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
    let onDateSelected: (Date) -> Void
    
    private var monthText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 月表示
            Text(monthText)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 5日分の日付を横並び
            HStack(spacing: 0) {
                ForEach(displayDates, id: \.self) { date in
                    PlanDateButton(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct PlanDateButton: View {
    let date: Date
    let isSelected: Bool
    let onTap: () -> Void
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private var day: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(dayOfWeek)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .secondary)
                
                Text(day)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.teal : Color.clear)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

