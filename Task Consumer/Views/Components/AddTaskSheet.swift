//
//  AddTaskSheet.swift
//  Task ToDo
//
//  Created by ryunosuke sato on 2025/12/21.
//

import SwiftUI
import SwiftData

struct AddTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let date: Date
    let viewModel: TaskViewModel
    let onSave: (TaskItem) -> Void
    
    @State private var title: String = ""
    @State private var isStandaloneMode: Bool = false // false: コンテナ, true: 単独タスク
    @State private var selectedDuration: Int = 30 // デフォルト30分
    @State private var parentTask: TaskItem? = nil
    @State private var availableParents: [TaskItem] = []
    @FocusState private var isTitleFocused: Bool
    
    private let durationOptions = Array(stride(from: 5, through: 180, by: 5)) // 5分刻みで5分〜180分
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // タイトル入力
                VStack(alignment: .leading, spacing: 8) {
                    Text(AppText.AddTask.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField(AppText.AddTask.titlePlaceholder, text: $title)
                        .textFieldStyle(.roundedBorder)
                        .focused($isTitleFocused)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // モード切替トグル
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $isStandaloneMode.animation(.spring(response: 0.3, dampingFraction: 0.7))) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(isStandaloneMode ? AppText.AddTask.standaloneMode : AppText.AddTask.containerMode)
                                .font(.body)
                            Text(isStandaloneMode ? AppText.AddTask.standaloneDescription : AppText.AddTask.containerDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 時間設定エリア（トグルがONの時のみ表示）
                    if isStandaloneMode {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(AppText.AddTask.duration)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Picker(AppText.AddTask.duration, selection: $selectedDuration) {
                                ForEach(durationOptions, id: \.self) { minutes in
                                    Text("\(minutes)\(AppText.TaskEdit.minutes)").tag(minutes)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                        }
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                
                // 親タスク選択
                VStack(alignment: .leading, spacing: 8) {
                    Text(AppText.AddTask.parentTask)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Picker(AppText.AddTask.parentTask, selection: $parentTask) {
                        Text(AppText.TaskEdit.none).tag(nil as TaskItem?)
                        ForEach(availableParents) { parent in
                            Text(parent.title).tag(parent as TaskItem?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle(AppText.AddTask.newTask)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppText.Common.cancel) {
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
                // フォーカスをタイトルフィールドに設定
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTitleFocused = true
                }
                loadAvailableParents()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
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
        } catch {
            availableParents = []
        }
    }
    
    private func saveTask() {
        // コンテナモードの場合: manualDuration = 0
        // 単独モードの場合: manualDuration = selectedDuration
        let manualDuration = isStandaloneMode ? selectedDuration : 0
        
        let newTask = TaskItem(
            title: title,
            date: date,
            parent: parentTask,
            plannedDuration: manualDuration,
            manualDuration: manualDuration
        )
        
        // 親タスクが指定されている場合、親子関係を確実に設定
        // SwiftDataの@Relationshipは自動的に逆参照を更新しますが、
        // 明示的にparentを設定することで確実に保存されます
        if let parent = parentTask {
            newTask.parent = parent
        }
        
        modelContext.insert(newTask)
        
        // 変更を保存（親子関係を含む）
        do {
            try modelContext.save()
        } catch {
            print("Error saving task: \(error)")
        }
        
        onSave(newTask)
        dismiss()
    }
}

#Preview {
    AddTaskSheet(
        date: Date(),
        viewModel: TaskViewModel(),
        onSave: { _ in }
    )
    .modelContainer(for: TaskItem.self, inMemory: true)
}


