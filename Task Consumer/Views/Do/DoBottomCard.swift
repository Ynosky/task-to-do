//
//  DoBottomCard.swift
//  Task Consumer
//
//  Created by ryunosuke sato on 2025/12/21.
//

import SwiftUI

struct DoBottomCard: View {
    let subTasks: [TaskItem]
    let selectedParentTask: TaskItem?
    let onTaskToggle: (TaskItem) -> Void
    let onAddTask: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    if subTasks.isEmpty {
                        // 子タスクがない場合のメッセージ
                        VStack(spacing: 16) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("子タスクがありません")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        // 子タスクリスト
                        ForEach(subTasks) { task in
                            DoSubTaskRow(
                                task: task,
                                onToggle: {
                                    onTaskToggle(task)
                                }
                            )
                        }
                    }
                    
                    // タスク追加行（常に表示）
                    DoAddTaskRow(onAdd: onAddTask)
                }
                .padding(.vertical, 16)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct DoSubTaskRow: View {
    let task: TaskItem
    let onToggle: () -> Void
    
    private var plannedTimeText: String {
        if let startTime = task.currentStartTime,
           let endTime = task.currentEndTime {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "目標: \(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
        }
        return "目標: 未設定"
    }
    
    private var actualTimeText: String {
        if let startTime = task.currentStartTime,
           let endTime = task.currentEndTime {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
        }
        return "-"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // チェックボックス
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .teal : .gray)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            
            // タスク情報
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                Text(plannedTimeText)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 実績時間
            Text(actualTimeText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct DoAddTaskRow: View {
    let onAdd: () -> Void
    
    var body: some View {
        Button(action: onAdd) {
            HStack(spacing: 12) {
                Image(systemName: "plus.square")
                    .foregroundColor(.teal)
                    .font(.title3)
                
                Text("タスクの追加")
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

