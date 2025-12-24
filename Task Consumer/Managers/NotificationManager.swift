//
//  NotificationManager.swift
//  Task Consumer
//
//  Created by ryunosuke sato on 2025/12/24.
//

import Foundation
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    private let notificationIdentifier = "TimerEnd"
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// 通知の許可をリクエスト
    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            } else if granted {
                print("Notification authorization granted")
            } else {
                print("Notification authorization denied")
            }
        }
    }
    
    /// 指定秒数後に通知をスケジュール
    /// - Parameters:
    ///   - seconds: 通知までの秒数
    ///   - title: 通知のタイトル
    ///   - body: 通知の本文
    func scheduleNotification(seconds: TimeInterval, title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        
        // 既存の通知をキャンセル（固定IDで上書きするため）
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
        
        // 通知コンテンツを作成
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        // トリガーを作成（指定秒数後）
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        
        // リクエストを作成（固定IDを使用）
        let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)
        
        // 通知をスケジュール
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled for \(seconds) seconds")
            }
        }
    }
    
    /// 予約されている通知をキャンセル
    func cancelNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [notificationIdentifier])
        // バッジをリセット
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// アプリがフォアグラウンドにある時に通知が配信された場合の処理
    /// フォアグラウンド時は通知バナーを表示しない（空のオプションを返す）
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // フォアグラウンド時は通知バナーも音も出さない（空のオプション）
        // アプリ内の実装（SoundManager等）に任せる
        completionHandler([])
    }
    
    /// 通知がタップされた時の処理（今回は未使用）
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // バッジをリセット
        UNUserNotificationCenter.current().setBadgeCount(0)
        completionHandler()
    }
}

