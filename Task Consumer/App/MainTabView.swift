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
    @AppStorage("userInterfaceStyle") private var userInterfaceStyle: String = "light"
    
    private var colorScheme: ColorScheme? {
        switch userInterfaceStyle {
        case "light":
            return .light
        case "dark":
            return .dark
        case "system":
            return nil
        default:
            return .light
        }
    }
    
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
        .preferredColorScheme(colorScheme)
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
    @AppStorage("userInterfaceStyle") private var userInterfaceStyle: String = "light"
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $userInterfaceStyle) {
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                        Text("System").tag("system")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("設定")
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: TaskItem.self, inMemory: true)
}

