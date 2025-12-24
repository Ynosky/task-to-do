//
//  AppText.swift
//  Agenda ToDo
//
//  Created by ryunosuke sato on 2025/12/21.
//

import SwiftUI

struct AppText {
    // MARK: - App Info
    struct App {
        static var name: String {
            "Agenda ToDo"
        }
    }
    
    // MARK: - Tab Bar
    struct Tab {
        static var plan: String {
            LanguageManager.shared.language == .japanese ? "計画" : "Plan"
        }
        static var doTab: String {
            LanguageManager.shared.language == .japanese ? "フォーカス" : "Do"
        }
        static var stats: String {
            LanguageManager.shared.language == .japanese ? "統計" : "Stats"
        }
        static var settings: String {
            LanguageManager.shared.language == .japanese ? "設定" : "Settings"
        }
    }
    
    // MARK: - Common
    struct Common {
        static var cancel: String {
            LanguageManager.shared.language == .japanese ? "キャンセル" : "Cancel"
        }
        static var save: String {
            LanguageManager.shared.language == .japanese ? "保存" : "Save"
        }
        static var delete: String {
            LanguageManager.shared.language == .japanese ? "削除" : "Delete"
        }
        static var edit: String {
            LanguageManager.shared.language == .japanese ? "編集" : "Edit"
        }
        static var done: String {
            LanguageManager.shared.language == .japanese ? "完了" : "Done"
        }
        static var close: String {
            LanguageManager.shared.language == .japanese ? "閉じる" : "Close"
        }
        static var ok: String {
            LanguageManager.shared.language == .japanese ? "OK" : "OK"
        }
        static var error: String {
            LanguageManager.shared.language == .japanese ? "エラー" : "Error"
        }
        static var today: String {
            LanguageManager.shared.language == .japanese ? "今日" : "Today"
        }
    }
    
    // MARK: - Plan View
    struct Plan {
        static var addTask: String {
            LanguageManager.shared.language == .japanese ? "タスクを追加" : "Add Task"
        }
        static var globalStartTime: String {
            LanguageManager.shared.language == .japanese ? "開始時間" : "Global Start Time"
        }
        static var noTimeSet: String {
            LanguageManager.shared.language == .japanese ? "時間未設定" : "No time set"
        }
        static var noSubTasks: String {
            LanguageManager.shared.language == .japanese ? "子タスクなし（0分）" : "No subtasks (0 min)"
        }
        static var taskTotal: String {
            LanguageManager.shared.language == .japanese ? "タスク合計: %d分" : "Task Total: %d min"
        }
        static func taskTotal(_ minutes: Int) -> String {
            String(format: taskTotal, minutes)
        }
        static var planLabel: String {
            LanguageManager.shared.language == .japanese ? "予定: " : "Plan: "
        }
        static var actLabel: String {
            LanguageManager.shared.language == .japanese ? "実績: " : "Act: "
        }
        static var notSet: String {
            LanguageManager.shared.language == .japanese ? "未設定" : "Not set"
        }
        static var gapTime: String {
            LanguageManager.shared.language == .japanese ? "休憩・スキマ時間" : "Break / Gap"
        }
        static var setStartTime: String {
            LanguageManager.shared.language == .japanese ? "開始時間を固定" : "Set Start Time"
        }
        static var unsetStartTime: String {
            LanguageManager.shared.language == .japanese ? "固定を解除" : "Unset Start Time"
        }
        static var moveUp: String {
            LanguageManager.shared.language == .japanese ? "上へ移動" : "Move Up"
        }
        static var moveDown: String {
            LanguageManager.shared.language == .japanese ? "下へ移動" : "Move Down"
        }
        static var fixedStartTime: String {
            LanguageManager.shared.language == .japanese ? "固定開始時間" : "Fixed Start Time"
        }
    }
    
    // MARK: - Do View
    struct Do {
        static var noTasks: String {
            LanguageManager.shared.language == .japanese ? "タスクがありません" : "No tasks"
        }
        static var complete: String {
            LanguageManager.shared.language == .japanese ? "完了" : "Complete"
        }
        static var start: String {
            LanguageManager.shared.language == .japanese ? "開始" : "Start"
        }
        static var finish: String {
            LanguageManager.shared.language == .japanese ? "終了" : "Finish"
        }
        static var noSubTasks: String {
            LanguageManager.shared.language == .japanese ? "子タスクがありません" : "No subtasks"
        }
        static var addSubtask: String {
            LanguageManager.shared.language == .japanese ? "子タスクを追加" : "Add Subtask"
        }
        static var moveUp: String {
            LanguageManager.shared.language == .japanese ? "上へ移動" : "Move Up"
        }
        static var moveDown: String {
            LanguageManager.shared.language == .japanese ? "下へ移動" : "Move Down"
        }
    }
    
    // MARK: - Stats View
    struct Stats {
        static var timeSaved: String {
            LanguageManager.shared.language == .japanese ? "節約時間" : "Time Saved"
        }
        static var tasksDone: String {
            LanguageManager.shared.language == .japanese ? "完了タスク" : "Tasks Done"
        }
        static var planningAccuracy: String {
            LanguageManager.shared.language == .japanese ? "計画精度（3日間平均）" : "Planning Accuracy (3-Day Avg)"
        }
        static var target: String {
            LanguageManager.shared.language == .japanese ? "目標: 80% - 120%" : "Target: 80% - 120%"
        }
        static var noData: String {
            LanguageManager.shared.language == .japanese ? "データが不足しています" : "No sufficient data yet"
        }
        static var tooLoose: String {
            LanguageManager.shared.language == .japanese ? "見積もりが甘い" : "Too Loose"
        }
        static var perfectZone: String {
            LanguageManager.shared.language == .japanese ? "適正な計画" : "Perfect Zone"
        }
        static var overtime: String {
            LanguageManager.shared.language == .japanese ? "見積もりが厳しい" : "Overtime"
        }
        static var workTime: String {
            LanguageManager.shared.language == .japanese ? "実施時間" : "Work Time"
        }
        static var noDataAvailable: String {
            LanguageManager.shared.language == .japanese ? "データがありません" : "No data available"
        }
        static var sevenDays: String {
            LanguageManager.shared.language == .japanese ? "7日間" : "7D"
        }
        static var oneMonth: String {
            LanguageManager.shared.language == .japanese ? "1ヶ月" : "1M"
        }
        static var sixMonths: String {
            LanguageManager.shared.language == .japanese ? "6ヶ月" : "6M"
        }
    }
    
    // MARK: - Settings
    struct Settings {
        static var title: String {
            LanguageManager.shared.language == .japanese ? "設定" : "Settings"
        }
        static var language: String {
            LanguageManager.shared.language == .japanese ? "言語" : "Language"
        }
        static var japanese: String {
            LanguageManager.shared.language == .japanese ? "日本語" : "Japanese"
        }
        static var english: String {
            LanguageManager.shared.language == .japanese ? "英語" : "English"
        }
        static var appearance: String {
            LanguageManager.shared.language == .japanese ? "外観" : "Appearance"
        }
        static var light: String {
            LanguageManager.shared.language == .japanese ? "ライト" : "Light"
        }
        static var dark: String {
            LanguageManager.shared.language == .japanese ? "ダーク" : "Dark"
        }
        static var system: String {
            LanguageManager.shared.language == .japanese ? "システム" : "System"
        }
        static var general: String {
            LanguageManager.shared.language == .japanese ? "一般" : "General"
        }
        static var notifications: String {
            LanguageManager.shared.language == .japanese ? "通知" : "Notifications"
        }
        static var support: String {
            LanguageManager.shared.language == .japanese ? "サポート" : "Support"
        }
        static var rateApp: String {
            LanguageManager.shared.language == .japanese ? "アプリを評価する" : "Rate this App"
        }
        static var contactUs: String {
            LanguageManager.shared.language == .japanese ? "お問い合わせ" : "Contact Us"
        }
        static var legal: String {
            LanguageManager.shared.language == .japanese ? "法律" : "Legal"
        }
        static var privacyPolicy: String {
            LanguageManager.shared.language == .japanese ? "プライバシーポリシー" : "Privacy Policy"
        }
        static var termsOfService: String {
            LanguageManager.shared.language == .japanese ? "利用規約" : "Terms of Service"
        }
        static var dataManagement: String {
            LanguageManager.shared.language == .japanese ? "データ管理" : "Data Management"
        }
        static var deleteAllData: String {
            LanguageManager.shared.language == .japanese ? "全データを削除" : "Delete All Data"
        }
        static var about: String {
            LanguageManager.shared.language == .japanese ? "このアプリについて" : "About"
        }
        static var version: String {
            LanguageManager.shared.language == .japanese ? "バージョン" : "Version"
        }
        static var deleteAllDataMessage: String {
            LanguageManager.shared.language == .japanese ? "すべてのタスクを削除してもよろしいですか？この操作は取り消せません。" : "Are you sure you want to delete all tasks? This action cannot be undone."
        }
        static var exportToCSV: String {
            LanguageManager.shared.language == .japanese ? "データをCSVで出力" : "Export Data as CSV"
        }
        static var timerNotification: String {
            LanguageManager.shared.language == .japanese ? "タイマー通知" : "Timer Notification"
        }
        static var sound: String {
            LanguageManager.shared.language == .japanese ? "音" : "Sound"
        }
        static var vibration: String {
            LanguageManager.shared.language == .japanese ? "振動" : "Vibration"
        }
    }
    
    // MARK: - Task Edit
    struct TaskEdit {
        static var editTask: String {
            LanguageManager.shared.language == .japanese ? "タスクを編集" : "Edit Task"
        }
        static var newTask: String {
            LanguageManager.shared.language == .japanese ? "新しいタスク" : "New Task"
        }
        static var basicInfo: String {
            LanguageManager.shared.language == .japanese ? "基本情報" : "Basic Information"
        }
        static var title: String {
            LanguageManager.shared.language == .japanese ? "タイトル" : "Title"
        }
        static var duration: String {
            LanguageManager.shared.language == .japanese ? "所要時間" : "Duration"
        }
        static var parentTask: String {
            LanguageManager.shared.language == .japanese ? "親タスク" : "Parent Task"
        }
        static var none: String {
            LanguageManager.shared.language == .japanese ? "なし" : "None"
        }
        static var subtaskTotal: String {
            LanguageManager.shared.language == .japanese ? "子タスクの合計時間: %d分" : "Subtask Total Time: %d min"
        }
        static func subtaskTotal(_ minutes: Int) -> String {
            String(format: subtaskTotal, minutes)
        }
        static var minutes: String {
            LanguageManager.shared.language == .japanese ? "分" : " min"
        }
        static var actualTime: String {
            LanguageManager.shared.language == .japanese ? "実績時間 (修正)" : "Actual Time (Edit)"
        }
        static var startTime: String {
            LanguageManager.shared.language == .japanese ? "開始時間" : "Start Time"
        }
        static var endTime: String {
            LanguageManager.shared.language == .japanese ? "終了時間" : "End Time"
        }
        static var isCompleted: String {
            LanguageManager.shared.language == .japanese ? "終了済み" : "Completed"
        }
        static var actualResult: String {
            LanguageManager.shared.language == .japanese ? "実績" : "Actual Result"
        }
        static var recordActualTime: String {
            LanguageManager.shared.language == .japanese ? "実績時間を記録する" : "Record Actual Time"
        }
    }
    
    // MARK: - Add Task
    struct AddTask {
        static var newTask: String {
            LanguageManager.shared.language == .japanese ? "新しいタスク" : "New Task"
        }
        static var title: String {
            LanguageManager.shared.language == .japanese ? "タイトル" : "Title"
        }
        static var titlePlaceholder: String {
            LanguageManager.shared.language == .japanese ? "タスクのタイトルを入力" : "Enter task title"
        }
        static var standaloneMode: String {
            LanguageManager.shared.language == .japanese ? "単独のタスクとして作成" : "Create as standalone task"
        }
        static var containerMode: String {
            LanguageManager.shared.language == .japanese ? "コンテナタスクとして作成" : "Create as container task"
        }
        static var standaloneDescription: String {
            LanguageManager.shared.language == .japanese ? "詳細な時間を設定" : "Set detailed time"
        }
        static var containerDescription: String {
            LanguageManager.shared.language == .japanese ? "後から子タスクを追加できます" : "You can add subtasks later"
        }
        static var duration: String {
            LanguageManager.shared.language == .japanese ? "所要時間" : "Duration"
        }
        static var parentTask: String {
            LanguageManager.shared.language == .japanese ? "親タスク（任意）" : "Parent Task (Optional)"
        }
    }
    
    // MARK: - Calendar
    struct Calendar {
        static var selectDate: String {
            LanguageManager.shared.language == .japanese ? "日付を選択" : "Select Date"
        }
        static var close: String {
            LanguageManager.shared.language == .japanese ? "閉じる" : "Close"
        }
        static var today: String {
            LanguageManager.shared.language == .japanese ? "今日" : "Today"
        }
    }
    
    // MARK: - Time Format
    struct TimeFormat {
        static func hours(_ h: Int) -> String {
            LanguageManager.shared.language == .japanese ? "\(h)時間" : "\(h)h"
        }
        static func minutes(_ m: Int) -> String {
            LanguageManager.shared.language == .japanese ? "\(m)分" : "\(m)m"
        }
        static func hoursAndMinutes(_ h: Int, _ m: Int) -> String {
            LanguageManager.shared.language == .japanese ? "\(h)時間\(m)分" : "\(h)h \(m)m"
        }
    }
    
    // MARK: - Links
    struct Links {
        static let privacyPolicyURL = URL(string: "https://docs.google.com/document/d/1LTNKbmoTXjPnpDQqd9WnUJLS4a53JT9VbO2fjWjUJ-4/edit?usp=sharing")!
        static let bottleMailURL = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLScpUGzJnZzknh4T9q-Rs0AKxg5Mv7tVyXxr3fcT50YQ-SjsLw/viewform?usp=header")!
        static let supportEmail = "dev.app.ynosuke@gmail.com"
    }
    
    // MARK: - Notification
    struct Notification {
        static var timerEndTitle: String {
            LanguageManager.shared.language == .japanese ? "時間です！🏁" : "Time's up! 🏁"
        }
        static var timerEndBody: String {
            LanguageManager.shared.language == .japanese ? "お疲れ様でした！フォーカスセッション完了です。" : "Great job! Focus session complete."
        }
    }
    
    // MARK: - Settings Support
    struct SettingsSupport {
        static var supportAndFeedback: String {
            LanguageManager.shared.language == .japanese ? "サポート・フィードバック" : "Support & Feedback"
        }
        static var sendBottleMail: String {
            LanguageManager.shared.language == .japanese ? "フィードバックを送る" : "Send us feedback"
        }
        static var bottleMailCaption: String {
            LanguageManager.shared.language == .japanese ? "バグ報告・改善要望" : "Bug reports & Feature requests"
        }
        static var contactUs: String {
            LanguageManager.shared.language == .japanese ? "お問い合わせ" : "Contact Us"
        }
        static var openMailApp: String {
            LanguageManager.shared.language == .japanese ? "メールアプリを開く" : "Open Mail App"
        }
        static var copyEmailAddress: String {
            LanguageManager.shared.language == .japanese ? "メールアドレスをコピー" : "Copy Email Address"
        }
    }
}

