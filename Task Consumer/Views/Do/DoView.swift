//
//  DoView.swift
//  Task ToDo
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
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Deep/Paperテーマの背景
                if colorScheme == .dark {
                    // Deep: 放射状グラデーション
                    RadialGradient(
                        colors: [
                            AppTheme.Deep.background,
                            AppTheme.Deep.backgroundSecondary,
                            AppTheme.Deep.background
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 800
                    )
                    .ignoresSafeArea()
                } else {
                    // Paper: セピアクリーム背景
                    AppTheme.Paper.background
                        .ignoresSafeArea()
                }
                
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
                        refreshID: viewModel.refreshID,
                        viewModel: viewModel,
                        selectedDate: viewModel.selectedDate,
                        onTaskToggle: { task in
                            handleTaskToggle(task)
                        },
                        onAddTask: {
                            handleAddSubTask()
                        },
                        onTaskEdit: { task in
                            editingTask = task
                            editingParentTask = task.parent
                            showingTaskEdit = true
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
        .alert(AppText.Common.error, isPresented: $showingError) {
            Button(AppText.Common.ok, role: .cancel) { }
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
                // 親タスクのIDを保存（子タスク追加後に再取得するため）
                let parentTaskId = viewModel.selectedParentTask?.id
                
                try viewModel.addTaskToDay(task, to: viewModel.selectedDate)
                
                // 子タスクを追加した場合、親タスクの関係を再読み込み
                // SwiftDataの関係は自動的に更新されるが、確実に反映させるため
                // 親タスクを再取得して、subTasksの関係を更新
                if let parentTaskId = parentTaskId {
                    // 親タスクを再取得（fetchParentTasksメソッドを使用）
                    let parentTasks = try viewModel.fetchParentTasks(for: viewModel.selectedDate)
                    if let updatedParent = parentTasks.first(where: { $0.id == parentTaskId }) {
                        viewModel.selectedParentTask = updatedParent
                    }
                }
                
                refreshSchedule()
                
                // 強制更新処理：Viewの再描画をトリガー
                viewModel.triggerRefresh()
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

