//
//  DoTopCard.swift
//  Task Consumer
//
//  Created by ryunosuke sato on 2025/12/21.
//

import SwiftUI

struct DoTopCard: View {
    let parentTasks: [TaskItem]
    @Binding var selectedParentTask: TaskItem?
    let viewModel: TaskViewModel
    let onBack: () -> Void
    
    var body: some View {
        if parentTasks.isEmpty {
            // タスクがない場合の表示
            VStack {
                Text("タスクがありません")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
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
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.teal)
                        .font(.headline)
                }
                
                Spacer()
                
                // 2段構成のタイトル表示
                VStack(alignment: .leading, spacing: 4) {
                    // 上段: 親タスク名
                    if let parentTitle = viewModel.selectedParentTask?.title {
                        Text(parentTitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // 下段: 現在実行中のタスク名（子タスク or 親タスク）
                    Text(viewModel.currentActiveTaskTitle)
                        .font(.title2)
                        .bold()
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // 戻るボタンとバランスを取るためのスペーサー
                Image(systemName: "chevron.left")
                    .opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)
            
            Spacer()
            
            // メイン：デジタル時計（1秒ごとに更新）
            TimelineView(.periodic(from: .now, by: 1.0)) { context in
                let now = context.date
                
                if let activeTask = activeTask {
                    let remaining = calculateRemainingTime(for: activeTask, at: now)
                    let isOverdue = remaining < 0
                    let timeString = formatRemainingTime(remaining)
                    
                    Text(timeString)
                        .font(.system(size: 70, weight: .bold, design: .monospaced))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .foregroundColor(isOverdue ? .red : .primary)
                } else {
                    // アクティブなタスクがない場合（全完了など）
                    Text("Complete")
                        .font(.system(size: 70, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // フッター
            VStack(spacing: 12) {
                // 現在アクティブなタスク名称
                if let activeTask = activeTask {
                    Text(activeTask.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("タスクなし")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 操作ボタン
                HStack(spacing: 20) {
                    // Start Button
                    Button(action: {
                        print("Start tapped")
                    }) {
                        Label("Start", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.teal)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    // Finish Button
                    Button(action: {
                        print("Finish tapped")
                    }) {
                        Label("Finish", systemImage: "checkmark")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}
