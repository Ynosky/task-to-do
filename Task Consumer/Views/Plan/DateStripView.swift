//
//  DateStripView.swift
//  Task Consumer
//
//  Created by ryunosuke sato on 2025/12/21.
//

import SwiftUI

struct DateStripView: View {
    @Binding var selectedDate: Date
    let displayDates: [Date]
    let viewModel: TaskViewModel
    let onDateSelected: (Date) -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(displayDates, id: \.self) { date in
                    PlanDateButton(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        taskCount: getTaskCount(for: date),
                        onTap: {
                            withAnimation(.easeInOut(duration: 1.0)) {
                                selectedDate = date
                                onDateSelected(date)
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        if value.translation.width > threshold {
                            if let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
                                withAnimation(.easeInOut(duration: 1.0)) {
                                    selectedDate = previousDate
                                    onDateSelected(previousDate)
                                }
                            }
                        } else if value.translation.width < -threshold {
                            if let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
                                withAnimation(.easeInOut(duration: 1.0)) {
                                    selectedDate = nextDate
                                    onDateSelected(nextDate)
                                }
                            }
                        }
                    }
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.clear) // 背景を透明に
        .overlay(
            // 下部に極薄の境界線
            Rectangle()
                .frame(height: 1)
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        )
    }
    
    // タスク数を取得（loadLevelから推測、または直接取得）
    private func getTaskCount(for date: Date) -> Int {
        do {
            let tasks = try viewModel.fetchAllTasks(for: date)
            return tasks.count
        } catch {
            return 0
        }
    }
}

struct PlanDateButton: View {
    let date: Date
    let isSelected: Bool
    let taskCount: Int // タスク数
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false
    
    // 曜日 (例: "Sat")
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    // 日付 (通常: "21", 選択時: "12/21")
    private var dateText: String {
        let formatter = DateFormatter()
        if isSelected {
            formatter.dateFormat = "M/d" // 選択時
        } else {
            formatter.dateFormat = "d"   // 通常時
        }
        return formatter.string(from: date)
    }
    
    // タスク量に応じたドット数と色を決定
    private var dotConfig: (count: Int, opacity: Double, hasGlow: Bool) {
        switch taskCount {
        case 0:
            return (0, 0, false)
        case 1...2:
            return (1, 0.3, false)
        case 3...4:
            return (2, 0.6, false)
        default: // 5個以上
            return (3, 1.0, true)
        }
    }
    
    // 未選択時の不透明度（ホバー時は60%）
    private var unselectedOpacity: Double {
        isHovered ? 0.6 : 0.4
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // 曜日
                Text(dayOfWeek)
                    .font(.system(size: 9, weight: .black, design: .default))
                    .tracking(2) // tracking-widest相当
                    .foregroundColor(isSelected ? .white : (colorScheme == .dark ? Color.white.opacity(unselectedOpacity) : Color.black.opacity(unselectedOpacity)))
                
                // 日付
                VStack(spacing: 4) {
                    Text(dateText)
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(isSelected ? .white : (colorScheme == .dark ? Color.white.opacity(unselectedOpacity) : Color.black.opacity(unselectedOpacity)))
                        .contentTransition(.numericText())
                    
                    // 選択時のシアンのアンダーライン（発光効果付き）
                    if isSelected {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(AppTheme.accent(for: colorScheme))
                            .shadow(
                                color: AppTheme.accent(for: colorScheme).opacity(0.5),
                                radius: 5,
                                x: 0,
                                y: 0
                            )
                            .frame(width: 20) // アンダーラインの幅
                    }
                }
                
                // タスク量インジケーター（バイオルミネセンス・ドット）
                HStack(spacing: 3) {
                    ForEach(0..<dotConfig.count, id: \.self) { index in
                        Circle()
                            .fill(AppTheme.accent(for: colorScheme).opacity(dotConfig.opacity))
                            .frame(width: 4, height: 4)
                            .shadow(
                                color: dotConfig.hasGlow ? AppTheme.accent(for: colorScheme).opacity(0.8) : Color.clear,
                                radius: 2.5,
                                x: 0,
                                y: 0
                            )
                    }
                }
                .frame(height: 4)
                .opacity(taskCount > 0 ? 1 : 0)
                .animation(.easeInOut(duration: 1.0), value: taskCount)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .scaleEffect(isSelected ? 1.1 : 1.0) // 選択時はスケールアップ
            .opacity(isSelected ? 1.0 : unselectedOpacity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 1.0), value: isSelected)
        .animation(.easeInOut(duration: 0.3), value: isHovered)
        .onHover { hovering in
            if !isSelected {
                isHovered = hovering
            }
        }
    }
}

