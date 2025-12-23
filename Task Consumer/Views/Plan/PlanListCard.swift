//
//  PlanListCard.swift
//  Agenda ToDo
//
//  Created by ryunosuke sato on 2025/12/21.
//

import SwiftUI
import SwiftData

struct PlanListCard: View {
    let selectedDate: Date
    let dayStartTime: Date
    let parentTasks: [TaskItem]
    let viewModel: TaskViewModel
    let onStartTimeChanged: (Date) -> Void
    let onTaskToggle: (TaskItem) -> Void
    let onSubTaskToggle: (TaskItem) -> Void
    let onAddTask: () -> Void
    let onTaskEdit: ((TaskItem) -> Void)?
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        selectedDate: Date,
        dayStartTime: Date,
        parentTasks: [TaskItem],
        viewModel: TaskViewModel,
        onStartTimeChanged: @escaping (Date) -> Void,
        onTaskToggle: @escaping (TaskItem) -> Void,
        onSubTaskToggle: @escaping (TaskItem) -> Void,
        onAddTask: @escaping () -> Void,
        onTaskEdit: ((TaskItem) -> Void)? = nil
    ) {
        self.selectedDate = selectedDate
        self.dayStartTime = dayStartTime
        self.parentTasks = parentTasks
        self.viewModel = viewModel
        self.onStartTimeChanged = onStartTimeChanged
        self.onTaskToggle = onTaskToggle
        self.onSubTaskToggle = onSubTaskToggle
        self.onAddTask = onAddTask
        self.onTaskEdit = onTaskEdit
    }
    
    // カスタムバインディング: ViewModelの保存ロジックに直接接続
    private var startTimeBinding: Binding<Date> {
        Binding(
            get: {
                viewModel.getDayStartTime(for: selectedDate)
            },
            set: { newTime in
                // 日付と時刻を結合
                let calendar = Calendar.current
                var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: newTime)
                components.hour = timeComponents.hour
                components.minute = timeComponents.minute
                components.second = 0
                
                if let combinedDate = calendar.date(from: components) {
                    // 1. 新しい時間を保存
                    viewModel.setDayStartTime(combinedDate, for: selectedDate)
                    // 2. スケジュールを即座に再計算
                    Task { @MainActor in
                        do {
                            try viewModel.updateCurrentSchedule(for: selectedDate)
                            viewModel.triggerRefresh()
                        } catch {
                            // エラーは静かに処理（UIでの表示は不要）
                        }
                    }
                }
            }
        )
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // 全体開始時間設定
            HStack {
                // ラベル
                Image(systemName: "clock")
                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                Text(AppText.Plan.globalStartTime)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                
                Spacer()
                
                // タップ可能な時間表示エリア
                HStack(spacing: 4) {
                    // 固定を表すロックアイコン
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                    
                    // 時刻ピッカー（見た目はテキストだがタップ可能）
                    DatePicker(
                        "",
                        selection: startTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden() // ラベルを隠してコンパクトに
                    .tint(AppTheme.accent(for: colorScheme))    // ピッカーの色
                }
                .foregroundColor(AppTheme.accent(for: colorScheme)) // 文字とアイコンの色
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppTheme.accent(for: colorScheme).opacity(0.1)) // 背景色
                .cornerRadius(8)
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(AppTheme.cardBackground(for: colorScheme))
            .cornerRadius(12)
            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            // 親タスクリスト
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(parentTasks.enumerated()), id: \.element.id) { index, task in
                        // 前のタスクを取得
                        let previousTask = index > 0 ? parentTasks[index - 1] : nil
                        
                        // ギャップ判定: 前のタスク終了時間 < 現在のタスク開始時間
                        if let prevEnd = previousTask?.currentEndTime,
                           let currStart = task.currentStartTime,
                           currStart > prevEnd {
                            let gapDuration = currStart.timeIntervalSince(prevEnd)
                            if gapDuration >= 60 { // 1分以上なら表示
                                // ギャップ表示行
                                GapTimeRow(duration: gapDuration)
                            }
                        }
                        
                        // タスクカード本体
                        PlanParentTaskCard(
                            task: task,
                            viewModel: viewModel,
                            selectedDate: selectedDate,
                            onTaskToggle: {
                                onTaskToggle(task)
                            },
                            onSubTaskToggle: { subTask in
                                onSubTaskToggle(subTask)
                            },
                            onTaskEdit: onTaskEdit != nil ? {
                                onTaskEdit!(task)
                            } : nil
                        )
                    }
                    
                    // タスク追加ボタン
                    Button(action: onAddTask) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(AppTheme.accent(for: colorScheme))
                            Text(AppText.Plan.addTask)
                                .foregroundColor(AppTheme.accent(for: colorScheme))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.cardBackground(for: colorScheme))
                        .cornerRadius(12)
                        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .overlay(
            // 極細の境界線のみ（Deepモードのみ）
            Group {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                }
            }
        )
    }
}

struct PlanParentTaskCard: View {
    let task: TaskItem
    let viewModel: TaskViewModel
    let selectedDate: Date
    let onTaskToggle: () -> Void
    let onSubTaskToggle: (TaskItem) -> Void
    let onTaskEdit: (() -> Void)?
    
    @State private var showingFixedTimePicker = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var timeRangeText: String {
        if let startTime = task.currentStartTime,
           let endTime = task.currentEndTime {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
        }
        return AppText.Plan.noTimeSet
    }
    
    private var durationText: String {
        let subTasks = task.subTasks ?? []
        if subTasks.isEmpty {
            // 子タスクがない場合
            if task.manualDuration > 0 {
                // 単独タスク: manualDurationを表示
                return "\(task.manualDuration)\(AppText.TaskEdit.minutes)"
            } else {
                // コンテナタスク（子タスクなし）: 0分と表示
                return AppText.Plan.noSubTasks
            }
        } else {
            // コンテナタスク: 子タスクの合計時間を表示
            let totalDuration = task.effectiveDuration
            if LanguageManager.shared.language == .japanese {
                return "タスク合計: \(totalDuration)分"
            } else {
                return "Task Total: \(totalDuration) min"
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private var subTasks: [TaskItem] {
        guard let subTasks = task.subTasks else {
            return []
        }
        return subTasks.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    // 進捗率を計算 (0.0 = 開始時, 1.0 = 終了時)
    // 現在時刻が開始時間と終了時間の間にある場合のみ値を返す
    private func calculateProgress(currentTime: Date) -> CGFloat? {
        guard let start = task.currentStartTime,
              let end = task.currentEndTime,
              !task.isCompleted else {
            return nil
        }
        
        // 期間外（まだ始まっていない、または既に終わった）なら nil を返す = オーブを表示しない
        guard currentTime >= start && currentTime < end else {
            return nil
        }
        
        let totalDuration = end.timeIntervalSince(start)
        let elapsed = currentTime.timeIntervalSince(start)
        
        return totalDuration > 0 ? CGFloat(elapsed / totalDuration) : 0
    }
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 5.0)) { timeline in
            let progress = calculateProgress(currentTime: timeline.date)
            
            VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            HStack {
                Text(task.title)
                    .font(.headline)
                    .italic(task.isCompleted) // 完了時はイタリック
                    .foregroundColor(
                        task.isCompleted 
                            ? (colorScheme == .dark 
                                ? AppTheme.completed(for: colorScheme) 
                                : Color.black.opacity(0.5)) // Paperモード: より濃い色で見やすく
                            : AppTheme.textPrimary(for: colorScheme)
                    )
                    .opacity(task.isCompleted ? (colorScheme == .dark ? 0.9 : 1.0) : 1.0) // Deep: 0.9, Paper: 1.0（不透明度はforegroundColorで調整）
                    .saturation(task.isCompleted && colorScheme == .dark ? 1.0 : 1) // Deep完了時は色を完全に戻す
                    // blurとoffsetを削除して可読性を最大化
                    .animation(.easeInOut(duration: 1.0), value: task.isCompleted) // 1秒のゆっくりとしたアニメーション
                
                Spacer()
                
                Button(action: onTaskToggle) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(task.isCompleted ? AppTheme.accent(for: colorScheme) : AppTheme.textTertiary(for: colorScheme))
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                // 予定時間と実績時間を横並びで表示
                HStack(spacing: 4) {
                    // 固定時間アイコン（設定されている場合）
                    if task.fixedStartTime != nil {
                        Image(systemName: "anchor")
                            .font(.caption2)
                            .foregroundColor(AppTheme.accent(for: colorScheme))
                    }
                    
                    // 予定時間
                    if let startTime = task.currentStartTime,
                       let endTime = task.currentEndTime {
                        Text("\(AppText.Plan.planLabel)\(formatTime(startTime)) - \(formatTime(endTime))")
                            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                    } else {
                        Text("\(AppText.Plan.planLabel)\(AppText.Plan.notSet)")
                            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                    }
                    
                    // 実績時間（条件付き表示）
                    if let actStart = task.actualStartTime {
                        Text(" / ")
                            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                        
                        if let actEnd = task.actualEndTime {
                            // 完了時: 青か赤で表示
                            Text("\(AppText.Plan.actLabel)\(formatTime(actStart)) - \(formatTime(actEnd))")
                                .foregroundColor(viewModel.actualTimeColor(for: task))
                        } else {
                            // 進行中
                            Text("\(AppText.Plan.actLabel)\(formatTime(actStart)) - ...")
                                .foregroundColor(.orange)
                        }
                    }
                }
                .font(.caption)
                
                Text(durationText)
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary(for: colorScheme).opacity(0.8))
            }
            
            // 子タスクリスト
            if !subTasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(subTasks) { subTask in
                        PlanSubTaskRow(
                            task: subTask,
                            viewModel: viewModel,
                            selectedDate: selectedDate,
                            onToggle: {
                                onSubTaskToggle(subTask)
                            }
                        )
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background {
            ZStack {
                // 基本の背景色
                AppTheme.cardBackground(for: colorScheme)
                
                // 進行中ならオーブアニメーションを重ねる
                if let progress = progress {
                    ProgressOrbBackground(progress: progress, colorScheme: colorScheme)
                }
            }
        }
        .opacity(task.isCompleted && colorScheme == .dark ? 0.9 : 1.0) // Deep完了時は0.9（可読度最大限向上）
        .saturation(task.isCompleted && colorScheme == .dark ? 1.0 : 1) // Deep完了時は色を完全に戻す
        // blurとoffsetを削除して可読性を最大化
        .animation(.easeInOut(duration: 1.0), value: task.isCompleted) // 1秒のゆっくりとしたアニメーション
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            // タスクを選択してDoViewに遷移
            viewModel.selectedParentTask = task
            viewModel.selectedTab = 1 // Doタブに切り替え
        }
        .contextMenu {
            // 開始時間を固定
            Button {
                showingFixedTimePicker = true
            } label: {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(AppTheme.accent(for: colorScheme))
                    Text(AppText.Plan.setStartTime)
                }
            }
            
            // 編集
            if let onTaskEdit = onTaskEdit {
                Button {
                    onTaskEdit()
                } label: {
                    Label(AppText.Common.edit, systemImage: "pencil")
                }
            }
            
            // 固定を解除
            if task.fixedStartTime != nil {
                Button {
                    Task { @MainActor in
                        task.fixedStartTime = nil
                        try? viewModel.modelContext?.save()
                        do {
                            try viewModel.updateCurrentSchedule(for: selectedDate)
                        } catch {
                            // エラーは静かに処理（UIでの表示は不要）
                        }
                    }
                } label: {
                    Label(AppText.Plan.unsetStartTime, systemImage: "xmark.circle")
                }
            }
            
            // 上へ移動
            if let currentIndex = viewModel.currentParentTasks.firstIndex(where: { $0.id == task.id }),
               currentIndex > 0 {
                Button {
                    Task { @MainActor in
                        do {
                            try viewModel.moveParentTaskUp(task, for: selectedDate)
                        } catch {
                            // エラーは静かに処理（UIでの表示は不要）
                        }
                    }
                } label: {
                    Label(AppText.Plan.moveUp, systemImage: "arrow.up")
                }
            }
            
            // 下へ移動
            if let currentIndex = viewModel.currentParentTasks.firstIndex(where: { $0.id == task.id }),
               currentIndex < viewModel.currentParentTasks.count - 1 {
                Button {
                    Task { @MainActor in
                        do {
                            try viewModel.moveParentTaskDown(task, for: selectedDate)
                        } catch {
                            // エラーは静かに処理（UIでの表示は不要）
                        }
                    }
                } label: {
                    Label(AppText.Plan.moveDown, systemImage: "arrow.down")
                }
            }
            
            // 削除
            Button(role: .destructive) {
                Task { @MainActor in
                    do {
                        try viewModel.deleteTask(task, for: selectedDate)
                    } catch {
                        // エラーは静かに処理（UIでの表示は不要）
                    }
                }
            } label: {
                Label(AppText.Common.delete, systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingFixedTimePicker) {
            FixedTimePickerSheet(
                task: task,
                selectedDate: selectedDate,
                viewModel: viewModel,
                onSave: { fixedTime in
                    Task { @MainActor in
                        task.fixedStartTime = fixedTime
                        try? viewModel.modelContext?.save()
                        do {
                            try viewModel.updateCurrentSchedule(for: selectedDate)
                        } catch {
                            // エラーは静かに処理（UIでの表示は不要）
                        }
                    }
                }
            )
        }
        } // TimelineViewのクロージャを閉じる
    }
}

struct PlanSubTaskRow: View {
    let task: TaskItem
    let viewModel: TaskViewModel
    let selectedDate: Date
    let onToggle: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    private var timeRangeText: String {
        if let startTime = task.currentStartTime,
           let endTime = task.currentEndTime {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
        }
        return "-"
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // 1. 完了チェックボックス
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? AppTheme.accent(for: colorScheme) : AppTheme.textTertiary(for: colorScheme))
            }
            .buttonStyle(.plain) // 行全体のタップと干渉しないように
            
            // 2. タスク名（完了時は沈み込みアニメーションを適用）
            Text(task.title)
                .font(.body)
                .italic(task.isCompleted) // 完了時はイタリック
                .strikethrough(task.isCompleted)
                .foregroundColor(
                    task.isCompleted 
                        ? (colorScheme == .dark 
                            ? AppTheme.completed(for: colorScheme) 
                            : Color.black.opacity(0.5)) // Paperモード: より濃い色で見やすく
                        : AppTheme.textPrimary(for: colorScheme)
                )
                .opacity(task.isCompleted ? (colorScheme == .dark ? 0.9 : 1.0) : 1.0) // Deep: 0.9, Paper: 1.0（不透明度はforegroundColorで調整）
                .saturation(task.isCompleted && colorScheme == .dark ? 1.0 : 1) // Deep完了時は色を完全に戻す
                // blurとoffsetを削除して可読性を最大化
                .animation(.easeInOut(duration: 1.0), value: task.isCompleted) // 1秒のゆっくりとしたアニメーション
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer() // これで時間を右端に寄せる
            
            // 3. 時間情報（右寄せ・縦積み）
            VStack(alignment: .trailing, spacing: 2) {
                // 予定時間
                if let startTime = task.currentStartTime,
                   let endTime = task.currentEndTime {
                    Text("\(formatTime(startTime)) - \(formatTime(endTime))")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                } else {
                    Text(AppText.Plan.notSet)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                }
                
                // 実績時間（あれば）
                if let actualStart = task.actualStartTime {
                    if let actualEnd = task.actualEndTime {
                        // 完了時
                        Text("\(formatTime(actualStart)) - \(formatTime(actualEnd))")
                            .font(.caption)
                            .foregroundColor(viewModel.actualTimeColor(for: task))
                    } else {
                        // 進行中
                        Text("\(formatTime(actualStart)) - ...")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(task.isCompleted && colorScheme == .dark ? 0.9 : 1.0) // Deep完了時は0.9（可読度最大限向上）
        .saturation(task.isCompleted && colorScheme == .dark ? 1.0 : 1) // Deep完了時は色を完全に戻す
        // blurとoffsetを削除して可読性を最大化
        .animation(.easeInOut(duration: 1.0), value: task.isCompleted) // 1秒のゆっくりとしたアニメーション
        .contextMenu {
            // 削除
            Button(role: .destructive) {
                Task { @MainActor in
                    // 子タスクの削除
                    // ※ 子タスクの日付は親と同じはずですが、念のため task.date を使用
                    try? viewModel.deleteTask(task, for: task.date)
                }
            } label: {
                Label(AppText.Common.delete, systemImage: "trash")
            }
        }
    }
}

// MARK: - Gap Time Row

struct GapTimeRow: View {
    let duration: TimeInterval
    @Environment(\.colorScheme) private var colorScheme
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalMinutes = Int(duration / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            if minutes > 0 {
                return AppText.TimeFormat.hoursAndMinutes(hours, minutes)
            } else {
                return AppText.TimeFormat.hours(hours)
            }
        } else {
            return AppText.TimeFormat.minutes(minutes)
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
            Text(AppText.Plan.gapTime)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
            Spacer()
            Text(formatDuration(duration))
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Fixed Time Picker Sheet

struct FixedTimePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let task: TaskItem
    let selectedDate: Date
    let viewModel: TaskViewModel
    let onSave: (Date?) -> Void
    
    @State private var selectedTime: Date
    
    init(task: TaskItem, selectedDate: Date, viewModel: TaskViewModel, onSave: @escaping (Date?) -> Void) {
        self.task = task
        self.selectedDate = selectedDate
        self.viewModel = viewModel
        self.onSave = onSave
        
        // 初期値: 既存の固定時間、またはタスクの開始時間、または現在時刻
        if let fixedTime = task.fixedStartTime {
            _selectedTime = State(initialValue: fixedTime)
        } else if let startTime = task.currentStartTime {
            _selectedTime = State(initialValue: startTime)
        } else {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
            components.hour = 9
            components.minute = 0
            _selectedTime = State(initialValue: calendar.date(from: components) ?? Date())
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(AppText.Plan.setStartTime)
                    .font(.headline)
                    .padding(.top)
                
                DatePicker(
                    AppText.TaskEdit.startTime,
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                Spacer()
            }
            .padding()
            .navigationTitle(AppText.Plan.fixedStartTime)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppText.Common.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppText.Common.save) {
                        // 日付と時刻を結合
                        let calendar = Calendar.current
                        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
                        components.hour = timeComponents.hour
                        components.minute = timeComponents.minute
                        components.second = 0
                        
                        if let combinedDate = calendar.date(from: components) {
                            onSave(combinedDate)
                        }
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Progress Orb Background

struct ProgressOrbBackground: View {
    let progress: CGFloat // 0.0 - 1.0
    let colorScheme: ColorScheme
    private var color: Color {
        AppTheme.accent(for: colorScheme)
    }
    
    var body: some View {
        GeometryReader { geo in
            // 玉のY座標: 進捗に合わせて上から下へ移動
            // progress 0のとき上端(y=0付近)、1のとき下端(y=height付近)
            let orbYPosition = geo.size.height * progress
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.4), color.opacity(0.1), .clear], // 透明度も少し下げる
                        center: .center,
                        startRadius: 0,
                        endRadius: geo.size.width * 0.4 // 半径も小さく
                    )
                )
                .frame(width: geo.size.width * 0.8, height: geo.size.width * 0.8) // サイズを縮小
                .blur(radius: 30) // ぼかしも少し控えめに
                .position(x: geo.size.width / 2, y: orbYPosition)
                // 滑らかに動くようにアニメーション付与
                .animation(.linear(duration: 1.0), value: progress)
        }
        .clipped() // カードからはみ出た部分をカット
    }
}

