//
//  TaskEditView.swift
//  Task ToDo
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
    @State private var duration: Int = 30
    @State private var parentTask: TaskItem?
    @State private var availableParents: [TaskItem] = []
    
    // 実績時間編集用のState変数
    @State private var actualStartTime: Date = Date()
    @State private var actualEndTime: Date = Date()
    @State private var hasActualStartTime: Bool = false // 開始しているか
    @State private var hasActualEndTime: Bool = false   // 終了しているか
    
    private let durationOptions = Array(stride(from: 5, through: 240, by: 5)) // 5分から240分まで5分刻み
    
    var isEditing: Bool {
        task != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(AppText.TaskEdit.basicInfo) {
                    TextField(AppText.TaskEdit.title, text: $title)
                }
                
                Section(AppText.TaskEdit.duration) {
                    // 子タスクがある場合は所要時間を編集できない
                    if let task = task, !(task.subTasks?.isEmpty ?? true) {
                        Text(AppText.TaskEdit.subtaskTotal(task.effectiveDuration))
                            .foregroundColor(.secondary)
                    } else {
                        Picker(AppText.TaskEdit.duration, selection: $duration) {
                            ForEach(durationOptions, id: \.self) { minutes in
                                Text("\(minutes)\(AppText.TaskEdit.minutes)").tag(minutes)
                            }
                        }
                    }
                }
                
                Section(AppText.TaskEdit.parentTask) {
                    Picker(AppText.TaskEdit.parentTask, selection: $parentTask) {
                        Text(AppText.TaskEdit.none).tag(nil as TaskItem?)
                        ForEach(availableParents) { parent in
                            Text(parent.title).tag(parent as TaskItem?)
                        }
                    }
                }
                
                // 実績時間編集セクション（開始済みの場合のみ表示）
                if hasActualStartTime {
                    Section(AppText.TaskEdit.actualTime) {
                        DatePicker(AppText.TaskEdit.startTime, selection: $actualStartTime)
                        
                        Toggle(AppText.TaskEdit.isCompleted, isOn: $hasActualEndTime)
                        
                        if hasActualEndTime {
                            DatePicker(AppText.TaskEdit.endTime, selection: $actualEndTime)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? AppText.TaskEdit.editTask : AppText.TaskEdit.newTask)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppText.Common.cancel) {
                        onDismiss()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppText.Common.save) {
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
            // 子タスクがない場合のみmanualDurationを表示
            duration = (task.subTasks?.isEmpty ?? true) ? task.manualDuration : 0
            parentTask = task.parent
            
            // 実績情報の読み込み
            if let start = task.actualStartTime {
                actualStartTime = start
                hasActualStartTime = true
            } else {
                hasActualStartTime = false
            }
            
            if let end = task.actualEndTime {
                actualEndTime = end
                hasActualEndTime = true
            } else {
                // 未終了の場合は現在時刻などを初期値に
                actualEndTime = Date()
                hasActualEndTime = false
            }
        } else {
            // 新規作成時は初期化
            hasActualStartTime = false
            hasActualEndTime = false
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
            
            // 子タスクがない場合のみmanualDurationを更新
            if existingTask.subTasks?.isEmpty ?? true {
                existingTask.manualDuration = duration
                existingTask.plannedDuration = duration // 後方互換性のため
            }
            
            if existingTask.parent?.id != parentTask?.id {
                existingTask.parent = parentTask
            }
            
            // 実績情報の反映（開始済みの場合）
            if hasActualStartTime {
                existingTask.actualStartTime = actualStartTime
                
                if hasActualEndTime {
                    existingTask.actualEndTime = actualEndTime
                    existingTask.isCompleted = true
                    
                    // 実績所要時間(分)の再計算
                    let duration = actualEndTime.timeIntervalSince(actualStartTime)
                    existingTask.actualDuration = max(0, Int(duration / 60))
                } else {
                    // 終了時間がない状態に戻す（実行中に戻す）
                    existingTask.actualEndTime = nil
                    existingTask.isCompleted = false
                    existingTask.actualDuration = nil
                }
            }
            
            taskToSave = existingTask
        } else {
            let newTask = TaskItem(
                title: title,
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

