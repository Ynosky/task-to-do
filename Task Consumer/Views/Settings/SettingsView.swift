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
        NavigationStack {
            List {
                // 1. Appearance
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $userInterfaceStyle) {
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                        Text("System").tag("system")
                    }
                    .pickerStyle(.segmented)
                }
                
                // 2. General
                Section(header: Text("General")) {
                    Button {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Label("Notifications", systemImage: "bell.badge")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                // 3. Support
                Section(header: Text("Support")) {
                    Button {
                        requestReview()
                    } label: {
                        Label("Rate this App", systemImage: "star")
                    }
                    .foregroundColor(.primary)
                    
                    Link(destination: URL(string: "https://twitter.com/example")!) {
                        HStack {
                            Label("Contact Us", systemImage: "envelope")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                // 4. Legal
                Section(header: Text("Legal")) {
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }
                .foregroundColor(.primary)
                
                // 5. Data Management
                Section(header: Text("Data Management")) {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete All Data", systemImage: "trash")
                    }
                }
                
                // 6. About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(appVersion) (\(buildNumber))")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("© 2025 Task ToDo")
                        .font(.caption)
                        .padding(.top, 8)
                }
            }
            .navigationTitle("Settings")
            // Dark Mode時の透過設定（Deep Theme対応）
            .scrollContentBackground(.hidden)
            .alert("Delete All Data", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("Are you sure you want to delete all tasks? This action cannot be undone.")
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

