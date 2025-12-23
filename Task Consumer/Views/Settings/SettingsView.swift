//
//  SettingsView.swift
//  Task ToDo
//
//  Created by ryunosuke sato on 2025/12/21.
//

import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @AppStorage("userInterfaceStyle") private var userInterfaceStyle: String = "light"
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingDeleteAlert = false
    
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
                    
                    // 3. General
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
                    
                    // 4. Support
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
                    
                    // 5. Legal
                    Section(header: Text(AppText.Settings.legal)) {
                        Link(destination: AppText.Links.privacyPolicyURL) {
                            Label(AppText.Settings.privacyPolicy, systemImage: "hand.raised")
                        }
                        Link(destination: URL(string: "https://example.com/terms")!) {
                            Label(AppText.Settings.termsOfService, systemImage: "doc.text")
                        }
                    }
                    .foregroundColor(.primary)
                    
                    // 6. Data Management
                    Section(header: Text(AppText.Settings.dataManagement)) {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label(AppText.Settings.deleteAllData, systemImage: "trash")
                        }
                    }
                    
                    // 7. About
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
            print("All data deleted successfully")
        } catch {
            print("Failed to delete all data: \(error)")
        }
    }
}

