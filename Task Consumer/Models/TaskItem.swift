//
//  TaskItem.swift
//  Task Consumer
//
//  Created by ryunosuke sato on 2025/12/21.
//

import Foundation
import SwiftData

@Model
final class TaskItem {
    // MARK: - 識別・基本情報
    var id: UUID
    var title: String
    var detail: String?
    var date: Date // タスクを実行する日付
    var isCompleted: Bool
    var orderIndex: Int
    var createdAt: Date
    
    // MARK: - 親子関係
    @Relationship(deleteRule: .cascade, inverse: \TaskItem.parent)
    var subTasks: [TaskItem]? = []
    
    var parent: TaskItem?
    
    // MARK: - 時間情報（現在・動的）
    // ドラッグ＆ドロップや遅延により常に再計算され、変動する値
    var plannedDuration: Int // 現在の予定所要時間（5分刻み）- 後方互換性のため保持
    var manualDuration: Int // 子タスクを持たない場合の所要時間（単独タスク用）
    var actualDuration: Int? // 完了後の実績時間（1分刻み）
    var currentStartTime: Date? // 計算された現在の開始時間
    var currentEndTime: Date? // 計算された現在の終了時間
    
    // MARK: - 実績時間（実際の開始・終了時刻）
    var actualStartTime: Date? // 実際の開始時刻（Startボタンで記録）
    var actualEndTime: Date? // 実際の終了時刻（Finishボタンで記録）
    
    // MARK: - Computed Properties
    
    /// 有効な所要時間を計算
    /// - 子タスクがある場合: 子タスクの合計時間
    /// - 子タスクがない場合: manualDuration
    var effectiveDuration: Int {
        if let subTasks = subTasks, !subTasks.isEmpty {
            // コンテナモード: 子タスクの合計時間
            return subTasks.reduce(0) { $0 + $1.effectiveDuration }
        } else {
            // 単独モード: manualDuration
            return manualDuration
        }
    }
    
    // MARK: - 時間情報（初期計画・静的）
    // タスク作成時（または計画確定時）に値を固定し、自動計算の影響を受けない値
    var initialPlannedDuration: Int? // 最初に設定した所要時間
    var initialStartTime: Date? // 最初にスケジュールされた開始時間
    var initialEndTime: Date? // 最初にスケジュールされた終了時間
    
    init(
        id: UUID = UUID(),
        title: String,
        detail: String? = nil,
        date: Date,
        isCompleted: Bool = false,
        orderIndex: Int = 0,
        createdAt: Date = Date(),
        parent: TaskItem? = nil,
        plannedDuration: Int = 0,
        manualDuration: Int = 0,
        actualDuration: Int? = nil,
        currentStartTime: Date? = nil,
        currentEndTime: Date? = nil,
        initialPlannedDuration: Int? = nil,
        initialStartTime: Date? = nil,
        initialEndTime: Date? = nil,
        actualStartTime: Date? = nil,
        actualEndTime: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.date = date
        self.isCompleted = isCompleted
        self.orderIndex = orderIndex
        self.createdAt = createdAt
        self.parent = parent
        self.plannedDuration = plannedDuration
        self.manualDuration = manualDuration
        self.actualDuration = actualDuration
        self.currentStartTime = currentStartTime
        self.currentEndTime = currentEndTime
        self.initialPlannedDuration = initialPlannedDuration
        self.initialStartTime = initialStartTime
        self.initialEndTime = initialEndTime
        self.actualStartTime = actualStartTime
        self.actualEndTime = actualEndTime
    }
}

