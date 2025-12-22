//
//  PlanListCard.swift
//  Task Consumer
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
    
    init(
        selectedDate: Date,
        dayStartTime: Date,
        parentTasks: [TaskItem],
        viewModel: TaskViewModel,
        onStartTimeChanged: @escaping (Date) -> Void,
        onTaskToggle: @escaping (TaskItem) -> Void,
        onSubTaskToggle: @escaping (TaskItem) -> Void,
        onAddTask: @escaping () -> Void
    ) {
        self.selectedDate = selectedDate
        self.dayStartTime = dayStartTime
        self.parentTasks = parentTasks
        self.viewModel = viewModel
        self.onStartTimeChanged = onStartTimeChanged
        self.onTaskToggle = onTaskToggle
        self.onSubTaskToggle = onSubTaskToggle
        self.onAddTask = onAddTask
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
                            print("Error updating schedule: \(error)")
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
                    .foregroundColor(.secondary)
                Text("Global Start Time")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
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
                    .tint(.teal)    // ピッカーの色
                }
                .foregroundColor(.teal) // 文字とアイコンの色
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.teal.opacity(0.1)) // 背景色
                .cornerRadius(8)
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            
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
                            }
                        )
                    }
                    
                    // タスク追加ボタン
                    Button(action: onAddTask) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.teal)
                            Text("タスクを追加")
                                .foregroundColor(.teal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct PlanParentTaskCard: View {
    let task: TaskItem
    let viewModel: TaskViewModel
    let selectedDate: Date
    let onTaskToggle: () -> Void
    let onSubTaskToggle: (TaskItem) -> Void
    
    @State private var showingFixedTimePicker = false
    
    private var timeRangeText: String {
        if let startTime = task.currentStartTime,
           let endTime = task.currentEndTime {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
        }
        return "時間未設定"
    }
    
    private var durationText: String {
        let subTasks = task.subTasks ?? []
        if subTasks.isEmpty {
            // 子タスクがない場合
            if task.manualDuration > 0 {
                // 単独タスク: manualDurationを表示
                return "\(task.manualDuration)分"
            } else {
                // コンテナタスク（子タスクなし）: 0分と表示
                return "子タスクなし（0分）"
            }
        } else {
            // コンテナタスク: 子タスクの合計時間を表示
            let totalDuration = task.effectiveDuration
            return "タスク合計: \(totalDuration)分"
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            HStack {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: onTaskToggle) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(task.isCompleted ? .teal : .gray)
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
                            .foregroundColor(.teal)
                    }
                    
                    // 予定時間
                    if let startTime = task.currentStartTime,
                       let endTime = task.currentEndTime {
                        Text("Plan: \(formatTime(startTime)) - \(formatTime(endTime))")
                            .foregroundColor(.secondary)
                    } else {
                        Text("Plan: 未設定")
                            .foregroundColor(.secondary)
                    }
                    
                    // 実績時間（条件付き表示）
                    if let actStart = task.actualStartTime {
                        Text(" / ")
                            .foregroundColor(.secondary)
                        
                        if let actEnd = task.actualEndTime {
                            // 完了時: 青か赤で表示
                            Text("Act: \(formatTime(actStart)) - \(formatTime(actEnd))")
                                .foregroundColor(viewModel.actualTimeColor(for: task))
                        } else {
                            // 進行中
                            Text("Act: \(formatTime(actStart)) - ...")
                                .foregroundColor(.orange)
                        }
                    }
                }
                .font(.caption)
                
                Text(durationText)
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.8))
            }
            
            // 子タスクリスト
            if !subTasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(subTasks) { subTask in
                        PlanSubTaskRow(
                            task: subTask,
                            viewModel: viewModel,
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
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
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
                Label("開始時間を固定", systemImage: "anchor")
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
                            print("Error updating schedule: \(error)")
                        }
                    }
                } label: {
                    Label("固定を解除", systemImage: "xmark.circle")
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
                            print("Error moving task up: \(error)")
                        }
                    }
                } label: {
                    Label("上へ移動", systemImage: "arrow.up")
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
                            print("Error moving task down: \(error)")
                        }
                    }
                } label: {
                    Label("下へ移動", systemImage: "arrow.down")
                }
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
                            print("Error updating schedule: \(error)")
                        }
                    }
                }
            )
        }
    }
}

struct PlanSubTaskRow: View {
    let task: TaskItem
    let viewModel: TaskViewModel
    let onToggle: () -> Void
    
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
                    .foregroundColor(task.isCompleted ? .teal : .gray)
            }
            .buttonStyle(.plain) // 行全体のタップと干渉しないように
            
            // 2. タスク名
            Text(task.title)
                .font(.body)
                .strikethrough(task.isCompleted)
                .foregroundColor(task.isCompleted ? .secondary : .primary)
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
                        .foregroundColor(.secondary)
                } else {
                    Text("未設定")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
    }
}

// MARK: - Gap Time Row

struct GapTimeRow: View {
    let duration: TimeInterval
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalMinutes = Int(duration / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            if minutes > 0 {
                return "\(hours)時間\(minutes)分"
            } else {
                return "\(hours)時間"
            }
        } else {
            return "\(minutes)分"
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("休憩・スキマ時間")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(formatDuration(duration))
                .font(.caption)
                .foregroundColor(.secondary)
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
                Text("開始時間を固定")
                    .font(.headline)
                    .padding(.top)
                
                DatePicker(
                    "開始時間",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                Spacer()
            }
            .padding()
            .navigationTitle("固定開始時間")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
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

