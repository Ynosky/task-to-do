//
//  PullToRefreshModifier.swift
//  Task Consumer
//
//  Created by ryunosuke sato on 2025/12/24.
//

import SwiftUI

struct PullToRefreshModifier: ViewModifier {
    @Binding var isRefreshing: Bool
    let onRefresh: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var rotationAngle: Double = 0
    
    private let threshold: CGFloat = 80
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
                .offset(y: isRefreshing ? threshold : max(0, dragOffset))
            
            // プレゼントアイコンの表示エリア
            if dragOffset > 0 || isRefreshing {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.pink)
                            .rotationEffect(.degrees(rotationAngle))
                            .scaleEffect(isRefreshing ? 1.2 : 1.0)
                            .animation(
                                isRefreshing
                                    ? Animation.linear(duration: 1.0).repeatForever(autoreverses: false)
                                    : .easeOut(duration: 0.2),
                                value: rotationAngle
                            )
                        
                        if isRefreshing {
                            Text("Loading...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: threshold)
                    .opacity(min(1.0, (dragOffset / threshold) * 1.5))
                    Spacer()
                }
                .offset(y: -threshold + min(dragOffset, threshold))
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if value.translation.height > 0 && !isRefreshing {
                        dragOffset = value.translation.height
                        rotationAngle = Double(value.translation.height / 5)
                    }
                }
                .onEnded { value in
                    if dragOffset > threshold && !isRefreshing {
                        isRefreshing = true
                        rotationAngle = 360
                        
                        // リフレッシュ処理
                        onRefresh()
                        
                        // アニメーション後、状態をリセット
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            withAnimation {
                                isRefreshing = false
                                dragOffset = 0
                                rotationAngle = 0
                            }
                        }
                    } else {
                        // 閾値を超えていない場合はスムーズに戻す
                        withAnimation {
                            dragOffset = 0
                            rotationAngle = 0
                        }
                    }
                }
        )
    }
}

extension View {
    func pullToRefresh(isRefreshing: Binding<Bool>, onRefresh: @escaping () -> Void) -> some View {
        modifier(PullToRefreshModifier(isRefreshing: isRefreshing, onRefresh: onRefresh))
    }
}

