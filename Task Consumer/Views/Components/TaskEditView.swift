//
//  TaskEditView.swift
//  Agenda ToDo
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
    @State private var editingActualStartTime: Date = Date()
    @State private var editingActualEndTime: Date = Date()
    @State private var hasActualTime: Bool = false // 実績時間を記録するか
    @State private var showActualTimeSection: Bool = false // 実績時間セクションを表示するか
    
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
                
                // 実績時間編集セクション（完了済み、または開始済みの場合に表示）
                if showActualTimeSection {
                    Section(header: Text(AppText.TaskEdit.actualResult)) {
                        Toggle(AppText.TaskEdit.recordActualTime, isOn: $hasActualTime)
                            .onChange(of: hasActualTime) { oldValue, newValue in
                                // トグルがONになった瞬間、値がnilの場合は初期値を設定
                                if newValue && oldValue == false {
                                    if let task = task {
                                        // 既存の実績時間がない場合、計画時間を初期値として使用
                                        if task.actualStartTime == nil {
                                            editingActualStartTime = task.currentStartTime ?? task.date
                                        }
                                        if task.actualEndTime == nil {
                                            editingActualEndTime = task.currentEndTime ?? Date()
                                        }
                                    }
                                }
                            }
                        
                        if hasActualTime {
                            VStack(alignment: .leading, spacing: 12) {
                                DatePicker(AppText.TaskEdit.startTime, selection: $editingActualStartTime, displayedComponents: [.date, .hourAndMinute])
                                
                                DatePicker(AppText.TaskEdit.endTime, selection: $editingActualEndTime, displayedComponents: [.date, .hourAndMinute])
                            }
                            .padding(.vertical, 4)
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
            // 完了済みタスク、または開始済みタスクの場合は実績時間セクションを表示
            let isCompleted = task.isCompleted
            
            // 完了済みの場合、または開始済みの場合に実績時間セクションを表示
            if isCompleted || task.actualStartTime != nil {
                showActualTimeSection = true
                
                // 実績時間が両方とも記録されているかチェック
                let hasBothTimes = task.actualStartTime != nil && task.actualEndTime != nil
                hasActualTime = hasBothTimes
                
                if let start = task.actualStartTime {
                    editingActualStartTime = start
                } else {
                    // 完了済みだが開始時間がない場合、デフォルト値を設定（計画開始時間またはその日の開始時刻）
                    editingActualStartTime = task.currentStartTime ?? task.date
                }
                
                if let end = task.actualEndTime {
                    editingActualEndTime = end
                } else {
                    // 終了時間がない場合、デフォルト値を設定（計画終了時間または現在時刻）
                    editingActualEndTime = task.currentEndTime ?? Date()
                }
            } else {
                // 未完了・未開始の場合は非表示
                showActualTimeSection = false
                hasActualTime = false
            }
        } else {
            // 新規作成時は初期化
            showActualTimeSection = false
            hasActualTime = false
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
            
            // 実績情報の反映（実績時間セクションが表示されている場合）
            if showActualTimeSection {
                if hasActualTime {
                    // トグルがONの場合、開始時間と終了時間の両方を設定
                    existingTask.actualStartTime = editingActualStartTime
                    existingTask.actualEndTime = editingActualEndTime
                    existingTask.isCompleted = true
                    
                    // 実績所要時間(分)の再計算
                    let duration = editingActualEndTime.timeIntervalSince(editingActualStartTime)
                    existingTask.actualDuration = max(0, Int(duration / 60))
                } else {
                    // トグルがOFFの場合、両方をnilにリセット
                    existingTask.actualStartTime = nil
                    existingTask.actualEndTime = nil
                    existingTask.actualDuration = nil
                    // 完了状態は維持（チェックボックスで管理されるため）
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

