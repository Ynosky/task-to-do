//
//  TaskToDoApp.swift
//  Agenda ToDo
//
//  Created by ryunosuke sato on 2025/12/21.
//

import SwiftUI
import SwiftData

@main
struct TaskToDoApp: App {
    @State private var localizationID = UUID()
    
    init() {
        // 通知許可をリクエスト
        NotificationManager.shared.requestAuthorization()
        // デリゲートを設定
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TaskItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .id(localizationID)
                .onReceive(NotificationCenter.default.publisher(for: NSLocale.currentLocaleDidChangeNotification)) { _ in
                    // システムの言語変更通知を受け取ったら、IDを更新して強制リフレッシュ
                    localizationID = UUID()
                }
                .onChange(of: LanguageManager.shared.language) { oldValue, newValue in
                    // アプリ内の言語設定変更時も強制リフレッシュ
                    localizationID = UUID()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

