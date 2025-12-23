//
//  PlanView.swift
//  Agenda ToDo
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
    @State private var showingCalendar = false
    @State private var editingTask: TaskItem?
    @State private var errorMessage: String?
    @State private var showingError = false
    
    // 選択された日付の親タスクを取得（orderIndex順）
    private var parentTasks: [TaskItem] {
        viewModel.currentParentTasks
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
                    // 日付選択ボタン
                    Button(action: { showingCalendar = true }) {
                        HStack {
                            Text(formattedFullDate)
                                .font(.title2)
                                .bold()
                                .foregroundColor(.primary)
                            
                            Image(systemName: "chevron.down.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.accent(for: colorScheme))
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                    }
                    .buttonStyle(.plain)
                    
                    // 上部カード: Date Selector
                    DateStripView(
                        selectedDate: $selectedDate,
                        displayDates: displayDates,
                        viewModel: viewModel,
                        onDateSelected: { date in
                            selectedDate = date
                            refreshSchedule()
                        }
                    )
                    .frame(height: geometry.size.height / 6)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
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
        .sheet(isPresented: $showingCalendar) {
            CalendarSheet(selectedDate: $selectedDate, viewModel: viewModel)
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
        .alert(AppText.Common.error, isPresented: $showingError) {
            Button(AppText.Common.ok, role: .cancel) { }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .onAppear {
            viewModel.modelContext = modelContext
            viewModel.selectedDate = selectedDate
            loadParentTasks()
            refreshSchedule()
        }
        .onChange(of: selectedDate) { _, newDate in
            viewModel.selectedDate = newDate
            loadParentTasks()
            refreshSchedule()
        }
        .onChange(of: viewModel.refreshTrigger) { _, _ in
            loadParentTasks()
        }
    }
    
    // MARK: - ヘルパーメソッド
    
    // 選択中の日付をフォーマット（例: "2025年12月21日"）
    private var formattedFullDate: String {
        let formatter = DateFormatter()
        if LanguageManager.shared.language == .japanese {
            formatter.dateFormat = "yyyy年M月d日"
            formatter.locale = Locale(identifier: "ja_JP")
        } else {
            formatter.dateStyle = .long
            formatter.locale = Locale(identifier: "en_US")
        }
        return formatter.string(from: selectedDate)
    }
    
    private func loadParentTasks() {
        Task { @MainActor in
            do {
                try viewModel.loadParentTasks(for: selectedDate)
            } catch {
                // エラーは静かに処理（UIでの表示は不要）
            }
        }
    }
    
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
                    // Hapticフィードバック: 未完了に戻す
                    HapticManager.shared.impact(style: .light)
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

