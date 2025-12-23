//
//  SettingsView.swift
//  Agenda ToDo
//
//  Created by ryunosuke sato on 2025/12/21.
//

import SwiftUI
import SwiftData
import StoreKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @AppStorage("userInterfaceStyle") private var userInterfaceStyle: String = "light"
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingDeleteAlert = false
    @State private var csvFileURL: URL?
    @AppStorage("timerSound") private var timerSound: TimerSoundType = .chime
    
    // アプリバージョン情報
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
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
            
            NavigationStack {
                List {
                    // 1. Language
                    Section(header: Text(AppText.Settings.language)) {
                        Picker(selection: Binding(
                            get: { LanguageManager.shared.language },
                            set: { LanguageManager.shared.language = $0 }
                        ), label: Text(AppText.Settings.language)) {
                            Text(AppText.Settings.japanese).tag(AppLanguage.japanese)
                            Text(AppText.Settings.english).tag(AppLanguage.english)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // 2. Appearance
                    Section(header: Text(AppText.Settings.appearance)) {
                        Picker("Theme", selection: $userInterfaceStyle) {
                            Text(AppText.Settings.light).tag("light")
                            Text(AppText.Settings.dark).tag("dark")
                            Text(AppText.Settings.system).tag("system")
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // 3. Timer Notification
                    Section(header: Text(AppText.Settings.timerNotification)) {
                        Picker(AppText.Settings.sound, selection: $timerSound) {
                            ForEach(TimerSoundType.allCases) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .onChange(of: timerSound) { oldValue, newValue in
                            // プレビュー再生
                            SoundManager.shared.play(newValue)
                        }
                    }
                    
                    // 4. General
                    Section(header: Text(AppText.Settings.general)) {
                        Button {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Label(AppText.Settings.notifications, systemImage: "bell.badge")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                    
                    // 5. Support
                    Section(header: Text(AppText.Settings.support)) {
                        Button {
                            requestReview()
                        } label: {
                            Label(AppText.Settings.rateApp, systemImage: "star")
                        }
                        .foregroundColor(.primary)
                        
                        Link(destination: AppText.Links.supportFormURL) {
                            HStack {
                                Label(AppText.Settings.contactUs, systemImage: "envelope")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                    
                    // 6. Legal
                    Section(header: Text(AppText.Settings.legal)) {
                        Link(destination: AppText.Links.privacyPolicyURL) {
                            Label(AppText.Settings.privacyPolicy, systemImage: "hand.raised")
                        }
                    }
                    .foregroundColor(.primary)
                    
                    // 7. Data Management
                    Section(header: Text(AppText.Settings.dataManagement)) {
                        if let csvURL = csvFileURL {
                            ShareLink(item: csvURL, preview: SharePreview("Tasks.csv")) {
                                Label(AppText.Settings.exportToCSV, systemImage: "square.and.arrow.up")
                            }
                            .foregroundColor(.primary)
                        } else {
                            Button {
                                generateCSV()
                            } label: {
                                Label(AppText.Settings.exportToCSV, systemImage: "square.and.arrow.up")
                            }
                            .foregroundColor(.primary)
                        }
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label(AppText.Settings.deleteAllData, systemImage: "trash")
                        }
                    }
                    
                    // 8. About
                    Section {
                        HStack {
                            Text(AppText.Settings.version)
                            Spacer()
                            Text("\(appVersion) (\(buildNumber))")
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text(AppText.Settings.about)
                    } footer: {
                        Text("© 2025 \(AppText.App.name)")
                            .font(.caption)
                            .padding(.top, 8)
                    }
                }
                .navigationTitle(AppText.Settings.title)
                // リストの背景を透明にして、背面のテーマ背景色が見えるようにする
                .scrollContentBackground(.hidden)
                .alert(AppText.Settings.deleteAllData, isPresented: $showingDeleteAlert) {
                    Button(AppText.Common.cancel, role: .cancel) { }
                    Button(AppText.Common.delete, role: .destructive) {
                        deleteAllData()
                    }
                } message: {
                    Text(AppText.Settings.deleteAllDataMessage)
                }
            }
        }
    }
    
    // 全データ削除ロジック
    private func deleteAllData() {
        do {
            let descriptor = FetchDescriptor<TaskItem>()
            let tasks = try modelContext.fetch(descriptor)
            
            for task in tasks {
                modelContext.delete(task)
            }
            
            try modelContext.save()
        } catch {
            // エラーは静かに処理（UIでの表示は不要）
        }
    }
    
    // CSV生成ロジック
    private func generateCSV() {
        do {
            let descriptor = FetchDescriptor<TaskItem>(
                sortBy: [SortDescriptor(\.date, order: .forward), SortDescriptor(\.orderIndex, order: .forward)]
            )
            let allTasks = try modelContext.fetch(descriptor)
            
            var csvContent = "Title,Status,Parent Task,Target Start Time,Target End Time,Actual Start Time,Actual End Time\n"
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            
            for task in allTasks {
                // Title (CSVエスケープ処理)
                let title = escapeCSVField(task.title)
                
                // Status
                let status = task.isCompleted ? "Completed" : "Active"
                
                // Parent Task
                let parentTitle = task.parent?.title ?? ""
                let parentTitleEscaped = parentTitle.isEmpty ? "" : escapeCSVField(parentTitle)
                
                // Target Start Time
                let targetStartTime = task.currentStartTime.map { dateFormatter.string(from: $0) } ?? ""
                
                // Target End Time
                let targetEndTime = task.currentEndTime.map { dateFormatter.string(from: $0) } ?? ""
                
                // Actual Start Time
                let actualStartTime = task.actualStartTime.map { dateFormatter.string(from: $0) } ?? ""
                
                // Actual End Time
                let actualEndTime = task.actualEndTime.map { dateFormatter.string(from: $0) } ?? ""
                
                // CSV行を構築
                csvContent += "\(title),\(status),\(parentTitleEscaped),\(targetStartTime),\(targetEndTime),\(actualStartTime),\(actualEndTime)\n"
            }
            
            // 一時ファイルとして保存
            let tempDir = FileManager.default.temporaryDirectory
            let timestampFormatter = DateFormatter()
            timestampFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
            let fileName = "Tasks_\(timestampFormatter.string(from: Date())).csv"
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            csvFileURL = fileURL
            
        } catch {
            // エラーは静かに処理
            print("CSV generation error: \(error)")
        }
    }
    
    // CSVフィールドのエスケープ処理（カンマ、改行、ダブルクォートを処理）
    private func escapeCSVField(_ field: String) -> String {
        // カンマ、改行、ダブルクォートが含まれる場合はダブルクォートで囲む
        if field.contains(",") || field.contains("\n") || field.contains("\"") {
            // ダブルクォートをエスケープ（2つのダブルクォートに置き換え）
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}

