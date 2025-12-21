//
//  TaskViewModel.swift
//  Task Consumer
//
//  Created by ryunosuke sato on 2025/12/21.
//

import Foundation
import SwiftData
import SwiftUI
import Observation

/// タスク管理のコアロジックを担当するViewModel
@Observable
final class TaskViewModel {
    var modelContext: ModelContext?
    var selectedParentTask: TaskItem?
    var selectedDate: Date = Date()
    var selectedTab: Int = 0 // 0: Plan, 1: Do, 2: Stats, 3: Settings
    
    // 現在表示中の親タスクリスト（Viewのデータソース）
    var currentParentTasks: [TaskItem] = []
    
    // データ更新のトリガー（Viewの再計算を促すため）
    var refreshTrigger: UUID = UUID()
    
    // 日付ごとの開始時間を保存（日付の文字列をキーとして使用）
    private var dayStartTimes: [String: Date] = [:]
    
    // 現在アクティブなタスクのタイトルを取得
    var currentActiveTaskTitle: String {
        guard let parent = selectedParentTask else { return "No Task Selected" }
        
        // 未完了の最初の子タスクを探す（orderIndex順）
        if let subTasks = parent.subTasks, !subTasks.isEmpty {
            let sortedSubTasks = subTasks.sorted { $0.orderIndex < $1.orderIndex }
            if let firstSubTask = sortedSubTasks.first(where: { !$0.isCompleted }) {
                return firstSubTask.title
            }
        }
        
        // 子タスクがない、または全て完了している場合は親タスクのタイトル
        return parent.title
    }
    
    /// データ更新をトリガーしてViewを再計算させる
    @MainActor
    func triggerRefresh() {
        refreshTrigger = UUID()
    }
    
    // その日の開始時間を取得（設定されていない場合は初期値を計算して保存）
    func getDayStartTime(for date: Date) -> Date {
        let calendar = Calendar.current
        let dateKey = dateKey(for: date)
        
        // メモリキャッシュから取得
        if let savedTime = dayStartTimes[dateKey] {
            return savedTime
        }
        
        // UserDefaultsから読み込み
        let userDefaultsKey = "StartTime_\(dateKey)"
        if let savedTimeInterval = UserDefaults.standard.object(forKey: userDefaultsKey) as? TimeInterval {
            let savedTime = Date(timeIntervalSince1970: savedTimeInterval)
            dayStartTimes[dateKey] = savedTime // メモリキャッシュにも保存
            return savedTime
        }
        
        // 保存されていない場合のみ、初期値を計算（現在時刻から次の5分切り上げ）
        let now = Date()
        let components = calendar.dateComponents([.hour, .minute], from: now)
        let currentMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        let next5Min = ((currentMinutes / 5) + 1) * 5
        
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = next5Min / 60
        dateComponents.minute = next5Min % 60
        dateComponents.second = 0
        
        let calculatedTime: Date
        if let time = calendar.date(from: dateComponents) {
            calculatedTime = time
        } else {
            // フォールバック: 9:00
            dateComponents.hour = 9
            dateComponents.minute = 0
            calculatedTime = calendar.date(from: dateComponents) ?? date
        }
        
        // 計算した初期値を保存（メモリキャッシュとUserDefaultsの両方）
        dayStartTimes[dateKey] = calculatedTime
        UserDefaults.standard.set(calculatedTime.timeIntervalSince1970, forKey: userDefaultsKey)
        
        return calculatedTime
    }
    
    // その日の開始時間を設定（メモリキャッシュとUserDefaultsの両方に保存）
    func setDayStartTime(_ time: Date, for date: Date) {
        let dateKey = dateKey(for: date)
        let userDefaultsKey = "StartTime_\(dateKey)"
        
        // メモリキャッシュに保存
        dayStartTimes[dateKey] = time
        
        // UserDefaultsに永続化
        UserDefaults.standard.set(time.timeIntervalSince1970, forKey: userDefaultsKey)
    }
    
    // 日付のキーを生成（yyyy-MM-dd形式）
    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar.current
        return formatter.string(from: date)
    }
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    /// 選択中の親タスクの子タスク一覧を取得
    func getSubTasks(for parentTask: TaskItem?) -> [TaskItem] {
        guard let parentTask = parentTask,
              let subTasks = parentTask.subTasks else {
            return []
        }
        return subTasks.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    /// 現在実行中の子タスクを取得
    func getCurrentSubTask(for parentTask: TaskItem?) -> TaskItem? {
        guard let parentTask = parentTask,
              let subTasks = parentTask.subTasks else {
            return nil
        }
        let sortedSubTasks = subTasks.sorted { $0.orderIndex < $1.orderIndex }
        let now = Date()
        
        // 現在時刻が含まれる最初の未完了タスクを返す
        for subTask in sortedSubTasks {
            if !subTask.isCompleted,
               let startTime = subTask.currentStartTime,
               let endTime = subTask.currentEndTime,
               startTime <= now && now <= endTime {
                return subTask
            }
        }
        
        // 現在時刻が含まれるタスクがない場合、次の未完了タスクを返す
        return sortedSubTasks.first { !$0.isCompleted }
    }
    
    // MARK: - グローバル・タイム・スタッキング（動的計算）
    
    /// 現在のスケジュールを計算し、全てのタスクのcurrentStartTimeとcurrentEndTimeを更新する
    /// - Parameter date: 計算対象の日付
    @MainActor
    func updateCurrentSchedule(for date: Date) throws {
        guard let modelContext = modelContext else {
            throw TaskViewModelError.modelContextNotSet
        }
        
        // その日の開始時間を取得
        let calendar = Calendar.current
        let dayStart = getDayStartTime(for: date)
        
        // 日付範囲を計算（その日の始まりから翌日の始まりまで）
        let startOfDay = calendar.startOfDay(for: date)
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // その日の親タスクを取得（親がないタスクのみ、orderIndexでソート）
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { task in
                task.date >= startOfDay && task.date < startOfNextDay && task.parent == nil
            },
            sortBy: [SortDescriptor(\.orderIndex, order: .forward)]
        )
        
        let parentTasks = try modelContext.fetch(descriptor)
        
        // 各親タスクに対して、連鎖的に時間を計算
        var currentTime = dayStart
        
        for parentTask in parentTasks {
            // 親タスクの開始時間を設定
            parentTask.currentStartTime = currentTime
            
            // 子タスクがある場合、親の開始時間から連鎖的に計算
            if let subTasks = parentTask.subTasks, !subTasks.isEmpty {
                let sortedSubTasks = subTasks.sorted { $0.orderIndex < $1.orderIndex }
                var subTaskStartTime = currentTime // 親の開始時間 = 最初の子タスクの開始時間
                
                for subTask in sortedSubTasks {
                    subTask.currentStartTime = subTaskStartTime
                    subTask.currentEndTime = calculateEndTime(
                        startTime: subTaskStartTime,
                        duration: subTask.effectiveDuration
                    )
                    
                    // 次の子タスクの開始時間は、この子タスクの終了時間
                    subTaskStartTime = subTask.currentEndTime ?? subTaskStartTime
                }
                
                // 親タスクの終了時間は、最後の子タスクの終了時間
                if let lastSubTask = sortedSubTasks.last,
                   let lastSubTaskEndTime = lastSubTask.currentEndTime {
                    parentTask.currentEndTime = lastSubTaskEndTime
                } else {
                    // 子タスクがない場合のフォールバック
                    parentTask.currentEndTime = currentTime
                }
            } else {
                // 子タスクがない場合、親タスク自体の所要時間を使用
                parentTask.currentEndTime = calculateEndTime(
                    startTime: currentTime,
                    duration: parentTask.effectiveDuration
                )
            }
            
            // 次の親タスクの開始時間は、この親タスクの終了時間
            currentTime = parentTask.currentEndTime ?? currentTime
        }
        
        // 変更を保存
        try modelContext.save()
    }
    
    /// 開始時間と所要時間から終了時間を計算
    /// - Parameters:
    ///   - startTime: 開始時間
    ///   - duration: 所要時間（分）
    /// - Returns: 終了時間
    private func calculateEndTime(startTime: Date, duration: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .minute, value: duration, to: startTime) ?? startTime
    }
    
    // MARK: - イニシャル・スナップショット（静的保存）
    
    /// タスクがその日のリストに初めて追加された時に、現在の計算結果を初期計画として保存
    /// - Parameter task: 対象タスク
    @MainActor
    func captureInitialSchedule(for task: TaskItem) throws {
        guard let modelContext = modelContext else {
            throw TaskViewModelError.modelContextNotSet
        }
        
        // 既に初期計画が保存されている場合はスキップ
        guard task.initialStartTime == nil && task.initialEndTime == nil else {
            return
        }
        
        // 現在の計算結果を初期計画として保存
        task.initialPlannedDuration = task.effectiveDuration
        task.initialStartTime = task.currentStartTime
        task.initialEndTime = task.currentEndTime
        
        // 子タスクがある場合、再帰的に初期計画を保存
        if let subTasks = task.subTasks {
            for subTask in subTasks {
                try captureInitialSchedule(for: subTask)
            }
        }
        
        // 変更を保存
        try modelContext.save()
    }
    
    /// タスクをその日のリストに追加し、初期計画を保存
    /// - Parameters:
    ///   - task: 追加するタスク
    ///   - date: 追加先の日付
    @MainActor
    func addTaskToDay(_ task: TaskItem, to date: Date) throws {
        guard let modelContext = modelContext else {
            throw TaskViewModelError.modelContextNotSet
        }
        
        // タスクの日付を更新
        task.date = date
        
        // 親タスクが指定されている場合、親子関係を確実に設定
        if let parent = task.parent {
            // 親のsubTasksに追加（SwiftDataの@Relationshipが自動的に更新しますが、明示的に設定）
            if parent.subTasks == nil {
                parent.subTasks = []
            }
            // 親のsubTasksに追加（重複チェック）
            if let subTasks = parent.subTasks, !subTasks.contains(where: { $0.id == task.id }) {
                // SwiftDataの@Relationshipは自動的に逆参照を更新するため、
                // task.parentを設定すれば親のsubTasksにも自動的に追加されます
                // ただし、明示的に保存することで確実にします
            }
            
            // 子タスクのorderIndexを設定（親の子タスクの中で最大のorderIndex + 1）
            let sortedSubTasks = (parent.subTasks ?? []).sorted { $0.orderIndex < $1.orderIndex }
            let maxSubTaskOrderIndex = sortedSubTasks.last?.orderIndex ?? -1
            task.orderIndex = maxSubTaskOrderIndex + 1
        } else {
            // 親タスクがない場合（親タスクとして作成）
            // その日の最大orderIndexを取得して、新しいタスクのorderIndexを設定
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let descriptor = FetchDescriptor<TaskItem>(
                predicate: #Predicate<TaskItem> { t in
                    t.date >= startOfDay && t.date < startOfNextDay && t.parent == nil
                },
                sortBy: [SortDescriptor(\.orderIndex, order: .reverse)]
            )
            
            let existingTasks = try modelContext.fetch(descriptor)
            let maxOrderIndex = existingTasks.first?.orderIndex ?? -1
            task.orderIndex = maxOrderIndex + 1
        }
        
        // 変更を保存（親子関係を含む）
        try modelContext.save()
        
        // スケジュールを再計算
        try updateCurrentSchedule(for: date)
        
        // 初期計画を保存
        try captureInitialSchedule(for: task)
        
        // Viewの再計算をトリガー
        triggerRefresh()
    }
    
    /// タスクの並び順を変更
    /// - Parameters:
    ///   - tasks: 並び替え後のタスク配列（親タスクのみ）
    ///   - date: 対象日付
    @MainActor
    func reorderTasks(_ tasks: [TaskItem], for date: Date) throws {
        guard let modelContext = modelContext else {
            throw TaskViewModelError.modelContextNotSet
        }
        
        // orderIndexを更新
        for (index, task) in tasks.enumerated() {
            task.orderIndex = index
        }
        
        // 変更を保存
        try modelContext.save()
        
        // スケジュールを再計算
        try updateCurrentSchedule(for: date)
        
        // Viewの再計算をトリガー
        triggerRefresh()
    }
    
    /// 親タスクの並び順を変更（ドラッグ＆ドロップ用）
    /// - Parameters:
    ///   - source: 移動元のインデックスセット
    ///   - destination: 移動先のインデックス
    ///   - date: 対象日付
    /// - Note: このメソッドはまずcurrentParentTasksを直接更新してUIを即座に反映させ、
    ///   その後orderIndexを更新して保存します。
    @MainActor
    func moveParentTasks(from source: IndexSet, to destination: Int, for date: Date) throws {
        guard let modelContext = modelContext else {
            throw TaskViewModelError.modelContextNotSet
        }
        
        // 重要: まずUI用の配列（currentParentTasks）を直接更新して、見た目の並び替えを即座に確定
        currentParentTasks.move(fromOffsets: source, toOffset: destination)
        
        // すべてのタスクに対して、新しい順序でorderIndexを0から順に振り直す
        for (index, task) in currentParentTasks.enumerated() {
            task.orderIndex = index
        }
        
        // 変更を保存（orderIndexの更新を含む）
        try modelContext.save()
        
        // スケジュールを再計算（新しい順序に基づいて時間を再計算）
        try updateCurrentSchedule(for: date)
        
        // Viewの再計算をトリガー（refreshTriggerを更新してViewを更新）
        triggerRefresh()
    }
    
    /// 子タスクの並び順を変更（ドラッグ＆ドロップ用）
    /// - Parameters:
    ///   - source: 移動元のインデックスセット
    ///   - destination: 移動先のインデックス
    ///   - parent: 親タスク
    ///   - date: 対象日付
    @MainActor
    func moveChildTasks(from source: IndexSet, to destination: Int, parent: TaskItem, for date: Date) throws {
        guard let modelContext = modelContext else {
            throw TaskViewModelError.modelContextNotSet
        }
        
        guard let subTasksArray = parent.subTasks else {
            return
        }
        
        // 配列に変換してorderIndex順でソート
        var reorderedSubTasks = Array(subTasksArray).sorted { $0.orderIndex < $1.orderIndex }
        
        // 並び替えを実行
        reorderedSubTasks.move(fromOffsets: source, toOffset: destination)
        
        // orderIndexを更新
        for (index, subTask) in reorderedSubTasks.enumerated() {
            subTask.orderIndex = index
        }
        
        // 親のsubTasksを更新（SwiftDataの@Relationshipが自動的に更新しますが、明示的に設定）
        parent.subTasks = reorderedSubTasks
        
        // 変更を保存
        try modelContext.save()
        
        // スケジュールを再計算
        try updateCurrentSchedule(for: date)
        
        // Viewの再計算をトリガー
        triggerRefresh()
    }
    
    /// 親タスクを1つ上に移動
    /// - Parameters:
    ///   - task: 移動するタスク
    ///   - date: 対象日付
    @MainActor
    func moveParentTaskUp(_ task: TaskItem, for date: Date) throws {
        guard let modelContext = modelContext else {
            throw TaskViewModelError.modelContextNotSet
        }
        
        // currentParentTasksから対象タスクのインデックスを取得
        guard let currentIndex = currentParentTasks.firstIndex(where: { $0.id == task.id }),
              currentIndex > 0 else {
            return // 先頭の場合は何もしない
        }
        
        // 1. 配列内で入れ替え
        currentParentTasks.swapAt(currentIndex - 1, currentIndex)
        
        // 2. orderIndexを0から連番で振り直し
        for (i, t) in currentParentTasks.enumerated() {
            t.orderIndex = i
        }
        
        // 3. 保存と再計算
        try modelContext.save()
        try updateCurrentSchedule(for: date)
        
        // Viewの再計算をトリガー
        triggerRefresh()
    }
    
    /// 親タスクを1つ下に移動
    /// - Parameters:
    ///   - task: 移動するタスク
    ///   - date: 対象日付
    @MainActor
    func moveParentTaskDown(_ task: TaskItem, for date: Date) throws {
        guard let modelContext = modelContext else {
            throw TaskViewModelError.modelContextNotSet
        }
        
        // currentParentTasksから対象タスクのインデックスを取得
        guard let currentIndex = currentParentTasks.firstIndex(where: { $0.id == task.id }),
              currentIndex < currentParentTasks.count - 1 else {
            return // 末尾の場合は何もしない
        }
        
        // 1. 配列内で入れ替え
        currentParentTasks.swapAt(currentIndex, currentIndex + 1)
        
        // 2. orderIndexを0から連番で振り直し
        for (i, t) in currentParentTasks.enumerated() {
            t.orderIndex = i
        }
        
        // 変更を保存
        try modelContext.save()
        
        // スケジュールを再計算
        try updateCurrentSchedule(for: date)
        
        // Viewの再計算をトリガー
        triggerRefresh()
    }
    
    /// 子タスクを1つ上に移動
    /// - Parameters:
    ///   - task: 移動するタスク
    ///   - parent: 親タスク
    ///   - date: 対象日付
    @MainActor
    func moveChildTaskUp(_ task: TaskItem, parent: TaskItem, for date: Date) throws {
        guard let modelContext = modelContext else {
            throw TaskViewModelError.modelContextNotSet
        }
        
        guard var subTasks = parent.subTasks else {
            return
        }
        
        // orderIndex順でソート
        subTasks = subTasks.sorted { $0.orderIndex < $1.orderIndex }
        
        // 対象タスクのインデックスを取得
        guard let currentIndex = subTasks.firstIndex(where: { $0.id == task.id }),
              currentIndex > 0 else {
            return // 先頭の場合は何もしない
        }
        
        // 1つ上のタスクと入れ替え
        let previousIndex = currentIndex - 1
        let previousTask = subTasks[previousIndex]
        
        // orderIndexを入れ替え
        let tempOrderIndex = task.orderIndex
        task.orderIndex = previousTask.orderIndex
        previousTask.orderIndex = tempOrderIndex
        
        // 親のsubTasksを更新
        parent.subTasks = subTasks
        
        // 変更を保存
        try modelContext.save()
        
        // スケジュールを再計算
        try updateCurrentSchedule(for: date)
        
        // Viewの再計算をトリガー
        triggerRefresh()
    }
    
    /// 子タスクを1つ下に移動
    /// - Parameters:
    ///   - task: 移動するタスク
    ///   - parent: 親タスク
    ///   - date: 対象日付
    @MainActor
    func moveChildTaskDown(_ task: TaskItem, parent: TaskItem, for date: Date) throws {
        guard let modelContext = modelContext else {
            throw TaskViewModelError.modelContextNotSet
        }
        
        guard var subTasks = parent.subTasks else {
            return
        }
        
        // orderIndex順でソート
        subTasks = subTasks.sorted { $0.orderIndex < $1.orderIndex }
        
        // 対象タスクのインデックスを取得
        guard let currentIndex = subTasks.firstIndex(where: { $0.id == task.id }),
              currentIndex < subTasks.count - 1 else {
            return // 末尾の場合は何もしない
        }
        
        // 1つ下のタスクと入れ替え
        let nextIndex = currentIndex + 1
        let nextTask = subTasks[nextIndex]
        
        // orderIndexを入れ替え
        let tempOrderIndex = task.orderIndex
        task.orderIndex = nextTask.orderIndex
        nextTask.orderIndex = tempOrderIndex
        
        // 親のsubTasksを更新
        parent.subTasks = subTasks
        
        // 変更を保存
        try modelContext.save()
        
        // スケジュールを再計算
        try updateCurrentSchedule(for: date)
        
        // Viewの再計算をトリガー
        triggerRefresh()
    }
    
    /// タスクの所要時間を変更（単独タスクの場合のみ有効）
    /// - Parameters:
    ///   - task: 対象タスク
    ///   - duration: 新しい所要時間（分、5分刻み）
    ///   - date: 対象日付
    @MainActor
    func updateTaskDuration(_ task: TaskItem, duration: Int, for date: Date) throws {
        guard let modelContext = modelContext else {
            throw TaskViewModelError.modelContextNotSet
        }
        
        // 子タスクがある場合は変更できない
        guard task.subTasks?.isEmpty ?? true else {
            throw TaskViewModelError.cannotUpdateDurationForContainerTask
        }
        
        // 5分刻みに丸める
        let roundedDuration = (duration / 5) * 5
        task.manualDuration = roundedDuration
        task.plannedDuration = roundedDuration // 後方互換性のため
        
        // 変更を保存
        try modelContext.save()
        
        // スケジュールを再計算
        try updateCurrentSchedule(for: date)
        
        // Viewの再計算をトリガー
        triggerRefresh()
    }
    
    /// タスクを完了にする
    /// - Parameter task: 対象タスク
    @MainActor
    func completeTask(_ task: TaskItem) throws {
        guard let modelContext = modelContext else {
            throw TaskViewModelError.modelContextNotSet
        }
        
        // 子タスクがある場合、全て完了しているか確認
        if let subTasks = task.subTasks, !subTasks.isEmpty {
            let allCompleted = subTasks.allSatisfy { $0.isCompleted }
            guard allCompleted else {
                throw TaskViewModelError.cannotCompleteParentWithIncompleteChildren
            }
        }
        
        task.isCompleted = true
        
        // 実績時間を記録（currentStartTimeとcurrentEndTimeから計算）
        if let startTime = task.currentStartTime,
           let endTime = task.currentEndTime {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.minute], from: startTime, to: endTime)
            task.actualDuration = components.minute
        }
        
        // 変更を保存
        try modelContext.save()
        
        // Viewの再計算をトリガー
        triggerRefresh()
    }
    
    /// 親タスクの完了状態を自動更新（子タスクが全て完了した場合）
    /// - Parameter parentTask: 親タスク
    @MainActor
    func updateParentCompletionStatus(_ parentTask: TaskItem) throws {
        guard let modelContext = modelContext else {
            throw TaskViewModelError.modelContextNotSet
        }
        
        if let subTasks = parentTask.subTasks, !subTasks.isEmpty {
            let allCompleted = subTasks.allSatisfy { $0.isCompleted }
            if allCompleted && !parentTask.isCompleted {
                parentTask.isCompleted = true
                try modelContext.save()
                
                // Viewの再計算をトリガー
                triggerRefresh()
            }
        }
    }
    
    /// タスクを削除し、スケジュールを再計算
    /// - Parameters:
    ///   - task: 削除するタスク
    ///   - date: 対象日付
    @MainActor
    func deleteTask(_ task: TaskItem, for date: Date) throws {
        guard let modelContext = modelContext else {
            throw TaskViewModelError.modelContextNotSet
        }
        
        modelContext.delete(task)
        try modelContext.save()
        
        // スケジュールを再計算
        try updateCurrentSchedule(for: date)
        
        // Viewの再計算をトリガー
        triggerRefresh()
    }
    
    /// 指定された日付の親タスク一覧を取得（内部用、後方互換性のため保持）
    /// - Parameter date: 対象日付
    /// - Returns: 親タスクの配列（必ずorderIndexの昇順でソート済み）
    @MainActor
    func fetchParentTasks(for date: Date) throws -> [TaskItem] {
        guard let modelContext = modelContext else {
            throw TaskViewModelError.modelContextNotSet
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // 必ずorderIndexの昇順でソート
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { task in
                task.date >= startOfDay && task.date < startOfNextDay && task.parent == nil
            },
            sortBy: [SortDescriptor(\.orderIndex, order: .forward)]
        )
        
        let tasks = try modelContext.fetch(descriptor)
        
        // 念のため、orderIndex順でソートして返す（二重チェック）
        return tasks.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    /// 指定された日付の親タスク一覧を読み込み、currentParentTasksを更新する
    /// - Parameter date: 対象日付
    /// - Note: このメソッドはcurrentParentTasksを更新します。Viewはこのプロパティを直接参照してください。
    @MainActor
    func loadParentTasks(for date: Date) throws {
        guard let modelContext = modelContext else {
            throw TaskViewModelError.modelContextNotSet
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // 必ずorderIndexの昇順でソート
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { task in
                task.date >= startOfDay && task.date < startOfNextDay && task.parent == nil
            },
            sortBy: [SortDescriptor(\.orderIndex, order: .forward)]
        )
        
        let tasks = try modelContext.fetch(descriptor)
        
        // currentParentTasksを更新（必ずorderIndex順でソート）
        currentParentTasks = tasks.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    /// 指定された日付の全タスク（親子関係を含む）を取得
    /// - Parameter date: 対象日付
    /// - Returns: タスクの配列
    @MainActor
    func fetchAllTasks(for date: Date) throws -> [TaskItem] {
        guard let modelContext = modelContext else {
            throw TaskViewModelError.modelContextNotSet
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { task in
                task.date >= startOfDay && task.date < startOfNextDay
            },
            sortBy: [SortDescriptor(\.orderIndex, order: .forward)]
        )
        
        return try modelContext.fetch(descriptor)
    }
}

// MARK: - エラー定義

enum TaskViewModelError: LocalizedError {
    case modelContextNotSet
    case cannotCompleteParentWithIncompleteChildren
    case cannotUpdateDurationForContainerTask
    
    var errorDescription: String? {
        switch self {
        case .modelContextNotSet:
            return "ModelContextが設定されていません"
        case .cannotCompleteParentWithIncompleteChildren:
            return "子タスクが全て完了していないため、親タスクを完了できません"
        case .cannotUpdateDurationForContainerTask:
            return "子タスクを持つタスクの所要時間は変更できません"
        }
    }
}

