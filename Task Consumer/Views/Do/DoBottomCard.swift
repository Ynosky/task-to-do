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
    let refreshID: UUID
    let viewModel: TaskViewModel
    let selectedDate: Date
    let onTaskToggle: (TaskItem) -> Void
    let onAddTask: () -> Void
    let onTaskEdit: (TaskItem) -> Void
    
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
                                viewModel: viewModel,
                                selectedDate: selectedDate,
                                onToggle: {
                                    onTaskToggle(task)
                                },
                                onEdit: {
                                    onTaskEdit(task)
                                }
                            )
                        }
                    }
                    
                    // タスク追加行（常に表示）
                    DoAddTaskRow(onAdd: onAddTask)
                }
                .padding(.vertical, 16)
            }
            .id(refreshID) // refreshIDが変わるたびにこのViewを強制再描画
        }
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct DoSubTaskRow: View {
    let task: TaskItem
    let viewModel: TaskViewModel
    let selectedDate: Date
    let onToggle: () -> Void
    let onEdit: () -> Void
    
    private var canMoveUp: Bool {
        guard let parent = task.parent,
              let subTasks = parent.subTasks else {
            return false
        }
        let sortedTasks = subTasks.sorted { $0.orderIndex < $1.orderIndex }
        guard let currentIndex = sortedTasks.firstIndex(where: { $0.id == task.id }) else {
            return false
        }
        return currentIndex > 0
    }
    
    private var canMoveDown: Bool {
        guard let parent = task.parent,
              let subTasks = parent.subTasks else {
            return false
        }
        let sortedTasks = subTasks.sorted { $0.orderIndex < $1.orderIndex }
        guard let currentIndex = sortedTasks.firstIndex(where: { $0.id == task.id }) else {
            return false
        }
        return currentIndex < sortedTasks.count - 1
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
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle()) // タップ領域確保
        .onTapGesture {
            onEdit()
        }
        .contextMenu {
            // 上へ移動
            if canMoveUp {
                Button {
                    Task { @MainActor in
                        viewModel.moveSubTaskUp(task)
                    }
                } label: {
                    Label("上へ移動", systemImage: "arrow.up")
                }
            }
            
            // 下へ移動
            if canMoveDown {
                Button {
                    Task { @MainActor in
                        viewModel.moveSubTaskDown(task)
                    }
                } label: {
                    Label("下へ移動", systemImage: "arrow.down")
                }
            }
            
            // 削除
            Button(role: .destructive) {
                Task { @MainActor in
                    try? viewModel.deleteTask(task, for: selectedDate)
                }
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
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
                
                Text("Add Subtask")
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

