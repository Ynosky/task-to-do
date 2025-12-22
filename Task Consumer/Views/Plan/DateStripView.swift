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
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(displayDates, id: \.self) { date in
                    PlanDateButton(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        loadLevel: viewModel.getTaskLoadLevel(for: date),
                        onTap: {
                            selectedDate = date
                            onDateSelected(date)
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
                                selectedDate = previousDate
                                onDateSelected(previousDate)
                            }
                        } else if value.translation.width < -threshold {
                            if let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
                                selectedDate = nextDate
                                onDateSelected(nextDate)
                            }
                        }
                    }
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct PlanDateButton: View {
    let date: Date
    let isSelected: Bool
    let loadLevel: Int // 0:なし, 1:少, 2:中, 3:多
    let onTap: () -> Void
    
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
    
    private var indicatorColor: Color {
        if isSelected {
            return .white
        } else {
            switch loadLevel {
            case 3: return .teal
            case 2: return .teal.opacity(0.7)
            case 1: return .teal.opacity(0.4)
            default: return .clear
            }
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                // 曜日
                Text(dayOfWeek)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                
                // 日付 (選択時は "12/21", 通常は "21")
                Text(dateText)
                    .font(isSelected ? .headline : .body) // 選択時は少し大きく強調
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .primary)
                    .contentTransition(.numericText())
                
                // タスク量ドット
                Circle()
                    .fill(indicatorColor)
                    .frame(width: 5, height: 5)
                    .opacity(loadLevel > 0 || isSelected ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                // 選択時の背景 (角丸長方形)
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.teal : Color.clear)
            )
            .contentShape(Rectangle()) // タップ領域を広げる
        }
        .buttonStyle(.plain)
    }
}

