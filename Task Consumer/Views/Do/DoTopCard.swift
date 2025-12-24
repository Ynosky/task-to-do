//
//  DoTopCard.swift
//  Agenda ToDo
//
//  Created by ryunosuke sato on 2025/12/21.
//

import SwiftUI

struct DoTopCard: View {
    let parentTasks: [TaskItem]
    @Binding var selectedParentTask: TaskItem?
    let viewModel: TaskViewModel
    let onBack: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        if parentTasks.isEmpty {
            // タスクがない場合の表示
            VStack {
                Text(AppText.Do.noTasks)
                    .font(.headline)
                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.cardBackground(for: colorScheme))
            .cornerRadius(20)
            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        } else {
            TabView(selection: $selectedParentTask) {
                ForEach(parentTasks) { task in
                    DoTopCardContent(
                        parentTask: task,
                        viewModel: viewModel,
                        onBack: onBack
                    )
                    .tag(task as TaskItem?)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: selectedParentTask?.id) { oldValue, newValue in
                // タスクカード切り替え時の触覚フィードバック
                if oldValue != newValue && newValue != nil {
                    HapticManager.shared.impact(style: .light)
                }
            }
        }
    }
}

struct DoTopCardContent: View {
    let parentTask: TaskItem
    let viewModel: TaskViewModel
    let onBack: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("timerSound") private var timerSound: TimerSoundType = .chime
    @State private var currentRemainingTime: TimeInterval?
    @State private var previousRemainingTime: TimeInterval?
    @State private var showConfetti = false
    
    // 現在アクティブなタスク（未完了の最初の子タスク、または子タスクがない場合は親タスク）
    private var activeTask: TaskItem? {
        if let subTasks = parentTask.subTasks, !subTasks.isEmpty {
            // 子タスクがある場合: 未完了の最初の子タスク
            let sortedSubTasks = subTasks.sorted { $0.orderIndex < $1.orderIndex }
            return sortedSubTasks.first { !$0.isCompleted }
        } else {
            // 子タスクがない場合: 親タスク自身
            return parentTask.isCompleted ? nil : parentTask
        }
    }
    
    // 残り時間を計算（秒単位）
    private func calculateRemainingTime(for task: TaskItem, at date: Date) -> TimeInterval {
        guard let endTime = task.currentEndTime else { return 0 }
        return endTime.timeIntervalSince(date)
    }
    
    // 残り時間を文字列にフォーマット
    private func formatRemainingTime(_ remaining: TimeInterval) -> String {
        let isNegative = remaining < 0
        let absRemaining = abs(remaining)
        let totalSeconds = Int(absRemaining)
        
        if totalSeconds >= 3600 {
            // 1時間以上: HH:MM:SS
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60
            return String(format: "%@%02d:%02d:%02d", isNegative ? "-" : "", hours, minutes, seconds)
        } else {
            // 1時間未満: MM:SS
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            return String(format: "%@%02d:%02d", isNegative ? "-" : "", minutes, seconds)
        }
    }
    
    // 実行中かどうかを判定
    private var isRunning: Bool {
        guard let task = activeTask else { return false }
        // 開始していて、まだ終了していない
        return task.actualStartTime != nil && task.actualEndTime == nil
    }
    
    // カード背景色
    private var cardBackgroundColor: Color {
        if isRunning {
            return colorScheme == .dark 
                ? AppTheme.Deep.accent.opacity(0.12)
                : AppTheme.Paper.accent.opacity(0.08)
        } else {
            return AppTheme.cardBackground(for: colorScheme)
        }
    }
    
    // カードボーダー
    private var cardBorder: some View {
        let borderColor: Color
        let lineWidth: CGFloat
        
        if isRunning {
            borderColor = colorScheme == .dark 
                ? AppTheme.Deep.accent.opacity(0.6)
                : AppTheme.Paper.accent.opacity(0.4)
            lineWidth = 2.5
        } else {
            borderColor = Color.clear
            lineWidth = 0
        }
        
        return RoundedRectangle(cornerRadius: 20)
            .stroke(borderColor, lineWidth: lineWidth)
    }
    
    // カードシャドウ色
    private var cardShadowColor: Color {
        if isRunning {
            return colorScheme == .dark 
                ? AppTheme.Deep.accent.opacity(0.25)
                : AppTheme.Paper.accent.opacity(0.15)
        } else {
            return colorScheme == .dark 
                ? Color.black.opacity(0.3)
                : Color.black.opacity(0.1)
        }
    }
    
    // カードシャドウ半径
    private var cardShadowRadius: CGFloat {
        isRunning ? 12 : 10
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                parentTaskTitleSection
                
                Spacer()
                
                centerSection
                
                Spacer()
                
                actionButtonsSection
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(cardBackgroundColor)
            .cornerRadius(20)
            .overlay(cardBorder)
            .shadow(color: cardShadowColor, radius: cardShadowRadius, x: 0, y: 5)
            
            // 紙吹雪エフェクト（最前面）
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
    }
    
    @ViewBuilder
    private var parentTaskTitleSection: some View {
        if let parentTitle = viewModel.selectedParentTask?.title {
            Text(parentTitle)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.top, 12)
                .padding(.horizontal, 16)
        }
    }
    
    private var centerSection: some View {
        VStack(spacing: 8) {
            timerView
            activeTaskTitleView
        }
    }
    
    private var timerView: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            timerContent(now: context.date)
        }
        .onChange(of: activeTask?.id) { oldValue, newValue in
            previousRemainingTime = nil
            currentRemainingTime = nil
        }
        .onChange(of: currentRemainingTime) { oldValue, newValue in
            // タイマーが0になった瞬間を検知
            if let previous = previousRemainingTime, let current = newValue, previous > 0 && current <= 0 {
                // タイマー完了時の通知（音の再生）
                // 音の再生（設定がnoneでない場合のみ）
                if timerSound != .none {
                    SoundManager.shared.play(timerSound)
                }
            }
            previousRemainingTime = newValue
        }
    }
    
    @ViewBuilder
    private func timerContent(now: Date) -> some View {
        if let activeTask = activeTask {
            timerActiveContent(task: activeTask, now: now)
        } else {
            timerInactiveContent
        }
    }
    
    @ViewBuilder
    private func timerActiveContent(task: TaskItem, now: Date) -> some View {
        let remaining = calculateRemainingTime(for: task, at: now)
        let isOverdue = remaining < 0
        let timeString = formatRemainingTime(remaining)
        
        Text(timeString)
            .font(.system(size: 60, weight: .bold, design: .monospaced))
            .monospacedDigit()
            .contentTransition(.numericText())
            .foregroundColor(isOverdue ? .red : AppTheme.textPrimary(for: colorScheme))
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .task(id: now) {
                // TimelineViewが更新されるたびに、残り時間をStateに保存
                currentRemainingTime = remaining
            }
    }
    
    @ViewBuilder
    private var timerInactiveContent: some View {
        Text(AppText.Do.complete)
            .font(.system(size: 60, weight: .bold, design: .monospaced))
            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .task {
                // アクティブタスクがない場合、Stateをリセット
                previousRemainingTime = nil
                currentRemainingTime = nil
            }
    }
    
    @ViewBuilder
    private var activeTaskTitleView: some View {
        let activeTaskTitle = viewModel.currentActiveTaskTitle
        let noTaskSelectedText = LanguageManager.shared.language == .japanese ? "タスクが選択されていません" : "No Task Selected"
        if !activeTaskTitle.isEmpty && activeTaskTitle != noTaskSelectedText {
            Text(activeTaskTitle)
                .font(.title2)
                .bold()
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }
    
    private var actionButtonsSection: some View {
        HStack(spacing: 20) {
            startButton
            finishButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private var startButton: some View {
        Button(action: startButtonAction) {
            Label(AppText.Do.start, systemImage: "play.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.accent(for: colorScheme))
                .foregroundColor(startButtonForegroundColor)
                .cornerRadius(12)
        }
        .disabled(activeTask == nil)
    }
    
    private func startButtonAction() {
        if let activeTask = activeTask {
            Task { @MainActor in
                viewModel.startTask(activeTask)
            }
        }
    }
    
    private var startButtonForegroundColor: Color {
        colorScheme == .dark ? AppTheme.Deep.background : .white
    }
    
    private var finishButton: some View {
        Button(action: finishButtonAction) {
            Label(AppText.Do.finish, systemImage: "checkmark")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.primary)
                .foregroundColor(Color(.systemBackground))
                .cornerRadius(12)
        }
        .disabled(activeTask == nil)
    }
    
    private func finishButtonAction() {
        if let activeTask = activeTask {
            // 1. 触覚フィードバック（強めの肯定的な振動）
            HapticManager.shared.notification(type: .success)
            
            // 2. 紙吹雪エフェクトを開始
            showConfetti = true
            
            // 3. タスクを完了
            Task { @MainActor in
                viewModel.finishTask(activeTask)
            }
            
            // 4. 2秒後に紙吹雪を非表示
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒
                showConfetti = false
            }
        }
    }
}
