//
//  TaskEditView.swift
//  Task Consumer
//
//  Created by ryunosuke sato on 2025/12/21.
//

import SwiftUI
import SwiftData

struct TaskEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let task: TaskItem?
    let date: Date
    let viewModel: TaskViewModel
    let initialParentTask: TaskItem?
    let onSave: (TaskItem) -> Void
    let onDismiss: () -> Void
    
    @State private var title: String = ""
    @State private var detail: String = ""
    @State private var duration: Int = 30
    @State private var parentTask: TaskItem?
    @State private var availableParents: [TaskItem] = []
    
    private let durationOptions = [15, 30, 45, 60, 90, 120, 180, 240]
    
    var isEditing: Bool {
        task != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("タイトル", text: $title)
                    
                    TextField("詳細（任意）", text: $detail, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("所要時間") {
                    // 子タスクがある場合は所要時間を編集できない
                    if let task = task, !(task.subTasks?.isEmpty ?? true) {
                        Text("子タスクの合計時間: \(task.effectiveDuration)分")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("所要時間", selection: $duration) {
                            ForEach(durationOptions, id: \.self) { minutes in
                                Text("\(minutes)分").tag(minutes)
                            }
                        }
                    }
                }
                
                Section("親タスク") {
                    Picker("親タスク", selection: $parentTask) {
                        Text("なし").tag(nil as TaskItem?)
                        ForEach(availableParents) { parent in
                            Text(parent.title).tag(parent as TaskItem?)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "タスクを編集" : "新しいタスク")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        onDismiss()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                loadTaskData()
                if let initialParent = initialParentTask {
                    parentTask = initialParent
                }
                loadAvailableParents()
            }
        }
    }
    
    private func loadTaskData() {
        if let task = task {
            title = task.title
            detail = task.detail ?? ""
            // 子タスクがない場合のみmanualDurationを表示
            duration = (task.subTasks?.isEmpty ?? true) ? task.manualDuration : 0
            parentTask = task.parent
        }
    }
    
    private func loadAvailableParents() {
        do {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let descriptor = FetchDescriptor<TaskItem>(
                predicate: #Predicate<TaskItem> { t in
                    t.date >= startOfDay && t.date < startOfNextDay && t.parent == nil
                },
                sortBy: [SortDescriptor(\.orderIndex, order: .forward)]
            )
            availableParents = try modelContext.fetch(descriptor)
            
            if let task = task {
                availableParents.removeAll { $0.id == task.id }
                let descendantIds = getDescendantIds(of: task)
                availableParents.removeAll { descendantIds.contains($0.id) }
            }
        } catch {
            availableParents = []
        }
    }
    
    private func getDescendantIds(of task: TaskItem) -> Set<UUID> {
        var ids: Set<UUID> = []
        if let subTasks = task.subTasks {
            for subTask in subTasks {
                ids.insert(subTask.id)
                ids.formUnion(getDescendantIds(of: subTask))
            }
        }
        return ids
    }
    
    private func saveTask() {
        let taskToSave: TaskItem
        
        if let existingTask = task {
            existingTask.title = title
            existingTask.detail = detail.isEmpty ? nil : detail
            
            // 子タスクがない場合のみmanualDurationを更新
            if existingTask.subTasks?.isEmpty ?? true {
                existingTask.manualDuration = duration
                existingTask.plannedDuration = duration // 後方互換性のため
            }
            
            if existingTask.parent?.id != parentTask?.id {
                existingTask.parent = parentTask
            }
            
            taskToSave = existingTask
        } else {
            let newTask = TaskItem(
                title: title,
                detail: detail.isEmpty ? nil : detail,
                date: date,
                parent: parentTask,
                plannedDuration: duration,
                manualDuration: duration
            )
            modelContext.insert(newTask)
            taskToSave = newTask
        }
        
        onSave(taskToSave)
        dismiss()
    }
}

#Preview {
    TaskEditView(
        task: nil,
        date: Date(),
        viewModel: TaskViewModel(),
        initialParentTask: nil,
        onSave: { _ in },
        onDismiss: {}
    )
    .modelContainer(for: TaskItem.self, inMemory: true)
}

