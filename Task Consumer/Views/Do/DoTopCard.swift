//
//  DoTopCard.swift
//  Task Consumer
//
//  Created by ryunosuke sato on 2025/12/21.
//

import SwiftUI

struct DoTopCard: View {
    let parentTasks: [TaskItem]
    @Binding var selectedParentTask: TaskItem?
    let viewModel: TaskViewModel
    let onBack: () -> Void
    let onExtend: () -> Void
    
    var body: some View {
        if parentTasks.isEmpty {
            // タスクがない場合の表示
            VStack {
                Text("タスクがありません")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        } else {
            TabView(selection: $selectedParentTask) {
                ForEach(parentTasks) { task in
                    DoTopCardContent(
                        parentTask: task,
                        viewModel: viewModel,
                        onBack: onBack,
                        onExtend: onExtend
                    )
                    .tag(task as TaskItem?)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}

struct DoTopCardContent: View {
    let parentTask: TaskItem
    let viewModel: TaskViewModel
    let onBack: () -> Void
    let onExtend: () -> Void
    
    // 現在実行中の子タスク
    private var currentSubTask: TaskItem? {
        viewModel.getCurrentSubTask(for: parentTask)
    }
    
    // 残り時間
    private var remainingTime: String {
        if let currentSubTask = currentSubTask,
           let endTime = currentSubTask.currentEndTime {
            let now = Date()
            let remaining = endTime.timeIntervalSince(now)
            if remaining > 0 {
                let minutes = Int(remaining) / 60
                let seconds = Int(remaining) % 60
                return String(format: "%02d:%02d", minutes, seconds)
            }
        }
        return "00:00"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.teal)
                        .font(.headline)
                }
                
                Spacer()
                
                Text(parentTask.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 戻るボタンとバランスを取るためのスペーサー
                Image(systemName: "chevron.left")
                    .opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Spacer()
            
            // メイン：デジタル時計
            Text(remainingTime)
                .font(.system(size: 60, weight: .bold, design: .monospaced))
                .foregroundColor(.teal)
            
            Spacer()
            
            // フッター
            HStack {
                // 現在実行中の子タスク名称
                if let currentSubTask = currentSubTask {
                    Text(currentSubTask.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("タスクなし")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 巻き戻しボタン
                Button(action: onExtend) {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundColor(.teal)
                        .font(.headline)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

