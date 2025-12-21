//
//  PlanListCard.swift
//  Task Consumer
//
//  Created by ryunosuke sato on 2025/12/21.
//

import SwiftUI

struct PlanListCard: View {
    let selectedDate: Date
    let dayStartTime: Date
    let parentTasks: [TaskItem]
    let viewModel: TaskViewModel
    let onStartTimeChanged: (Date) -> Void
    let onTaskToggle: (TaskItem) -> Void
    let onSubTaskToggle: (TaskItem) -> Void
    let onAddTask: () -> Void
    
    @State private var localStartTime: Date
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
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
        self._localStartTime = State(initialValue: dayStartTime)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // 全体開始時間設定
            VStack(alignment: .leading, spacing: 8) {
                Text("全体開始時間")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // デジタル時計風の表示
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text(formatTime(localStartTime))
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.teal)
                        
                        DatePicker(
                            "",
                            selection: $localStartTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .opacity(0.01)
                        .frame(width: 100, height: 20)
                    }
                    Spacer()
                }
                .onChange(of: localStartTime) { _, newTime in
                    let calendar = Calendar.current
                    var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: newTime)
                    components.hour = timeComponents.hour
                    components.minute = timeComponents.minute
                    components.second = 0
                    
                    if let combinedDate = calendar.date(from: components) {
                        onStartTimeChanged(combinedDate)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            // 親タスクリスト
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(parentTasks) { task in
                        PlanParentTaskCard(
                            task: task,
                            viewModel: viewModel,
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
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .onChange(of: dayStartTime) { _, newTime in
            localStartTime = newTime
        }
    }
}

struct PlanParentTaskCard: View {
    let task: TaskItem
    let viewModel: TaskViewModel
    let onTaskToggle: () -> Void
    let onSubTaskToggle: (TaskItem) -> Void
    
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
            return "子タスク合計: \(totalDuration)分"
        }
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
                Text(timeRangeText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
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
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            // タスクを選択してDoViewに遷移
            viewModel.selectedParentTask = task
            viewModel.selectedTab = 1 // Doタブに切り替え
        }
    }
}

struct PlanSubTaskRow: View {
    let task: TaskItem
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
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .teal : .gray)
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            
            Text(task.title)
                .font(.body)
                .strikethrough(task.isCompleted)
                .foregroundColor(task.isCompleted ? .secondary : .primary)
            
            Spacer()
            
            Text(timeRangeText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

