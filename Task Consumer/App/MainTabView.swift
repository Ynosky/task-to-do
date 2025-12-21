//
//  MainTabView.swift
//  Task Consumer
//
//  Created by ryunosuke sato on 2025/12/21.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var viewModel = TaskViewModel()
    
    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            // Plan (計画)
            PlanView(viewModel: viewModel)
                .tabItem {
                    Label("Plan", systemImage: "calendar")
                }
                .tag(0)
            
            // Do (実行)
            DoView(viewModel: viewModel)
                .tabItem {
                    Label("Do", systemImage: "checkmark.circle.fill")
                }
                .tag(1)
            
            // Stats (統計)
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
                .tag(2)
            
            // Settings (設定)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(3)
        }
        .tint(.teal)
    }
}

// MARK: - Stats View

struct StatsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Stats")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("統計")
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Settings")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("設定")
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: TaskItem.self, inMemory: true)
}

