//
//  CalendarSheet.swift
//  Task ToDo
//
//  Created by ryunosuke sato on 2025/12/21.
//

import SwiftUI
import UIKit

struct CalendarSheet: View {
    @Binding var selectedDate: Date
    let viewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            CalendarViewWrapper(selectedDate: $selectedDate, viewModel: viewModel)
                .padding()
                .navigationTitle("Select Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Today") {
                            selectedDate = Date()
                            dismiss()
                        }
                    }
                }
                .onChange(of: selectedDate) { _, _ in
                    dismiss() // 日付を選んだら閉じる
                }
        }
        .presentationDetents([.medium, .large])
    }
}

// UIKitのUICalendarViewをラップ
struct CalendarViewWrapper: UIViewRepresentable {
    @Binding var selectedDate: Date
    let viewModel: TaskViewModel

    func makeUIView(context: Context) -> UICalendarView {
        let view = UICalendarView()
        view.calendar = Calendar.current
        view.locale = Locale(identifier: "ja_JP")
        view.fontDesign = .rounded
        
        // 日付選択のデリゲート
        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        view.selectionBehavior = selection
        selection.selectedDate = Calendar.current.dateComponents(in: .current, from: selectedDate)
        
        // 装飾（ドット）のデリゲート
        view.delegate = context.coordinator
        
        return view
    }

    func updateUIView(_ uiView: UICalendarView, context: Context) {
        // 選択日の同期
        if let selection = uiView.selectionBehavior as? UICalendarSelectionSingleDate {
            let components = Calendar.current.dateComponents(in: .current, from: selectedDate)
            selection.selectedDate = components
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: CalendarViewWrapper

        init(parent: CalendarViewWrapper) {
            self.parent = parent
        }

        // 日付選択時
        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            guard let dateComponents = dateComponents,
                  let date = Calendar.current.date(from: dateComponents) else { return }
            
            parent.selectedDate = date
        }

        // 装飾（ドット表示）の定義
        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            guard let date = Calendar.current.date(from: dateComponents) else { return nil }
            
            // ViewModelから負荷レベルを取得 (0:なし, 1~3:あり)
            let level = parent.viewModel.getTaskLoadLevel(for: date)
            
            if level > 0 {
                // ドットの色設定（負荷レベルに応じて色を変える）
                let color: UIColor
                switch level {
                case 1:
                    color = .systemTeal.withAlphaComponent(0.5) // 軽い負荷
                case 2:
                    color = .systemTeal // 中程度の負荷
                case 3:
                    color = .systemTeal // 重い負荷（同じ色でもサイズで区別可能）
                default:
                    color = .systemTeal
                }
                return .default(color: color, size: .small)
            }
            return nil
        }
    }
}

