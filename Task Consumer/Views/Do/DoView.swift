//
//  DoView.swift
//  Task Consumer
//
//  Created by ryunosuke sato on 2025/12/21.
//

import SwiftUI
import SwiftData

struct DoView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: TaskViewModel
    @State private var showingTaskEdit = false
    @State private var editingTask: TaskItem?
    @State private var editingParentTask: TaskItem?
    @State private var errorMessage: String?
    @State private var showingError = false
    
    // 選択された日付の親タスクを取得
    private func getParentTasks() -> [TaskItem] {
        do {
            return try viewModel.fetchParentTasks(for: viewModel.selectedDate)
        } catch {
            return []
        }
    }
    
    // 選択中の親タスクの子タスク
    private func getSubTasks() -> [TaskItem] {
        viewModel.getSubTasks(for: viewModel.selectedParentTask)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景色
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 上部カード（Focus Area）
                    let parentTasks = getParentTasks()
                    DoTopCard(
                        parentTasks: parentTasks,
                        selectedParentTask: $viewModel.selectedParentTask,
                        viewModel: viewModel,
                        onBack: {
                            // 戻るボタンのアクション
                        }
                    )
                    .frame(height: geometry.size.height / 3 * 1.25)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // 下部カード（Task List）
                    let subTasks = getSubTasks()
                    DoBottomCard(
                        subTasks: subTasks,
                        selectedParentTask: viewModel.selectedParentTask,
                        onTaskToggle: { task in
                            handleTaskToggle(task)
                        },
                        onAddTask: {
                            handleAddSubTask()
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showingTaskEdit) {
            TaskEditView(
                task: editingTask,
                date: viewModel.selectedDate,
                viewModel: viewModel,
                initialParentTask: editingParentTask,
                onSave: { task in
                    handleTaskSave(task)
                },
                onDismiss: {
                    showingTaskEdit = false
                    editingTask = nil
                    editingParentTask = nil
                }
            )
        }
        .alert("エラー", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .onAppear {
            viewModel.modelContext = modelContext
            refreshSchedule()
            let tasks = getParentTasks()
            if viewModel.selectedParentTask == nil && !tasks.isEmpty {
                viewModel.selectedParentTask = tasks.first
            }
        }
        .onChange(of: viewModel.selectedDate) { _, _ in
            refreshSchedule()
            let tasks = getParentTasks()
            if viewModel.selectedParentTask == nil && !tasks.isEmpty {
                viewModel.selectedParentTask = tasks.first
            }
        }
    }
    
    // MARK: - ヘルパーメソッド
    
    private func refreshSchedule() {
        Task { @MainActor in
            do {
                try viewModel.updateCurrentSchedule(for: viewModel.selectedDate)
            } catch {
                showError(error.localizedDescription)
            }
        }
    }
    
    private func handleTaskToggle(_ task: TaskItem) {
        Task { @MainActor in
            do {
                if task.isCompleted {
                    task.isCompleted = false
                    try viewModel.modelContext?.save()
                } else {
                    try viewModel.completeTask(task)
                }
                
                if let parent = task.parent {
                    try viewModel.updateParentCompletionStatus(parent)
                }
                refreshSchedule()
            } catch {
                showError(error.localizedDescription)
            }
        }
    }
    
    private func handleAddSubTask() {
        editingTask = nil
        editingParentTask = viewModel.selectedParentTask
        showingTaskEdit = true
    }
    
    private func handleTaskSave(_ task: TaskItem) {
        Task { @MainActor in
            do {
                if task.modelContext == nil {
                    modelContext.insert(task)
                }
                try viewModel.addTaskToDay(task, to: viewModel.selectedDate)
                refreshSchedule()
            } catch {
                showError(error.localizedDescription)
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

#Preview {
    DoView(viewModel: TaskViewModel())
        .modelContainer(for: TaskItem.self, inMemory: true)
}

