//
//  PlanView.swift
//  Task Consumer
//
//  Created by ryunosuke sato on 2025/12/21.
//

import SwiftUI
import SwiftData

struct PlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: TaskViewModel
    @State private var selectedDate = Date()
    @State private var showingTaskEdit = false
    @State private var showingAddTask = false
    @State private var editingTask: TaskItem?
    @State private var errorMessage: String?
    @State private var showingError = false
    
    // 選択された日付の親タスクを取得（開始時間順にソート）
    private var parentTasks: [TaskItem] {
        do {
            let tasks = try viewModel.fetchParentTasks(for: selectedDate)
            return tasks.sorted { task1, task2 in
                let time1 = task1.currentStartTime ?? Date.distantPast
                let time2 = task2.currentStartTime ?? Date.distantPast
                return time1 < time2
            }
        } catch {
            return []
        }
    }
    
    // 表示する5日分の日付を計算
    private var displayDates: [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        
        for i in -2...2 {
            if let date = calendar.date(byAdding: .day, value: i, to: selectedDate) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    // 選択中の日付の開始時間
    private var dayStartTime: Date {
        viewModel.getDayStartTime(for: selectedDate)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 上部カード: Date Selector
                    DateStripView(
                        selectedDate: $selectedDate,
                        displayDates: displayDates,
                        onDateSelected: { date in
                            selectedDate = date
                            refreshSchedule()
                        }
                    )
                    .frame(height: geometry.size.height / 6)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // 下部カード: Planning Area
                    PlanListCard(
                        selectedDate: selectedDate,
                        dayStartTime: dayStartTime,
                        parentTasks: parentTasks,
                        viewModel: viewModel,
                        onStartTimeChanged: { newTime in
                            viewModel.setDayStartTime(newTime, for: selectedDate)
                            refreshSchedule()
                        },
                        onTaskToggle: { task in
                            handleTaskToggle(task)
                        },
                        onSubTaskToggle: { subTask in
                            handleTaskToggle(subTask)
                        },
                        onAddTask: {
                            showingAddTask = true
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskSheet(
                date: selectedDate,
                viewModel: viewModel,
                onSave: { task in
                    handleTaskSave(task)
                }
            )
        }
        .sheet(isPresented: $showingTaskEdit) {
            TaskEditView(
                task: editingTask,
                date: selectedDate,
                viewModel: viewModel,
                initialParentTask: nil,
                onSave: { task in
                    handleTaskSave(task)
                },
                onDismiss: {
                    showingTaskEdit = false
                    editingTask = nil
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
            viewModel.selectedDate = selectedDate
            refreshSchedule()
        }
        .onChange(of: selectedDate) { _, newDate in
            viewModel.selectedDate = newDate
            refreshSchedule()
        }
    }
    
    // MARK: - ヘルパーメソッド
    
    private func refreshSchedule() {
        Task { @MainActor in
            do {
                try viewModel.updateCurrentSchedule(for: selectedDate)
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
    
    private func handleTaskSave(_ task: TaskItem) {
        Task { @MainActor in
            do {
                if task.modelContext == nil {
                    modelContext.insert(task)
                }
                try viewModel.addTaskToDay(task, to: selectedDate)
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
    PlanView(viewModel: TaskViewModel())
        .modelContainer(for: TaskItem.self, inMemory: true)
}

