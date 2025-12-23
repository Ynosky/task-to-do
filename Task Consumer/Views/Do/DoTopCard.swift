//
//  DoTopCard.swift
//  Task ToDo
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
        }
    }
}

struct DoTopCardContent: View {
    let parentTask: TaskItem
    let viewModel: TaskViewModel
    let onBack: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
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
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 親タスク名（上部固定）
            if let parentTitle = viewModel.selectedParentTask?.title {
                Text(parentTitle)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                    .padding(.horizontal, 16)
            }
            
            Spacer()
            
            // 2. 中央部：デジタル時計と子タスク名
            VStack(spacing: 8) {
                // デジタル時計
                TimelineView(.periodic(from: .now, by: 1.0)) { context in
                    let now = context.date
                    
                    if let activeTask = activeTask {
                        let remaining = calculateRemainingTime(for: activeTask, at: now)
                        let isOverdue = remaining < 0
                        let timeString = formatRemainingTime(remaining)
                        
                        Text(timeString)
                            .font(.system(size: 60, weight: .bold, design: .monospaced))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .foregroundColor(isOverdue ? .red : AppTheme.textPrimary(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                    } else {
                        // アクティブなタスクがない場合（全完了など）
                        Text(AppText.Do.complete)
                            .font(.system(size: 60, weight: .bold, design: .monospaced))
                            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                    }
                }
                
                // 現在の子タスク名
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
            
            Spacer()
            
            // 3. 操作ボタン（下部固定）
            HStack(spacing: 20) {
                // Start Button
                Button(action: {
                    if let activeTask = activeTask {
                        Task { @MainActor in
                            viewModel.startTask(activeTask)
                        }
                    }
                }) {
                    Label(AppText.Do.start, systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.accent(for: colorScheme))
                        .foregroundColor(colorScheme == .dark ? AppTheme.Deep.background : .white)
                        .cornerRadius(12)
                }
                .disabled(activeTask == nil)
                
                // Finish Button
                Button(action: {
                    if let activeTask = activeTask {
                        Task { @MainActor in
                            viewModel.finishTask(activeTask)
                        }
                    }
                }) {
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
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Group {
                if isRunning {
                    // 実行中: 各モードに合わせた自然な背景色
                    if colorScheme == .dark {
                        // Deepモード: シアンの微かな光彩
                        AppTheme.Deep.accent.opacity(0.12)
                    } else {
                        // Paperモード: インク色の微かな光彩
                        AppTheme.Paper.accent.opacity(0.08)
                    }
                } else {
                    AppTheme.cardBackground(for: colorScheme)
                }
            }
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isRunning ? (
                        colorScheme == .dark 
                            ? AppTheme.Deep.accent.opacity(0.6) 
                            : AppTheme.Paper.accent.opacity(0.4)
                    ) : Color.clear, 
                    lineWidth: isRunning ? 2.5 : 0
                )
        )
        .shadow(
            color: isRunning 
                ? (colorScheme == .dark 
                    ? AppTheme.Deep.accent.opacity(0.25) 
                    : AppTheme.Paper.accent.opacity(0.15))
                : (colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)), 
            radius: isRunning ? 12 : 10, 
            x: 0, 
            y: 5
        )
    }
}
