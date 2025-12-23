//
//  ConfettiView.swift
//  Agenda ToDo
//
//  Created by ryunosuke sato on 2025/12/21.
//

import SwiftUI

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    struct ConfettiPiece: Identifiable {
        let id = UUID()
        let color: Color
        var position: CGPoint
        var rotation: Double
        var opacity: Double
        var size: CGFloat
        var velocity: CGPoint
    }
    
    // ライトモード向けのカラフルな色（ゴールド、明るいブルー、ピンク、イエローなど）
    private let colors: [Color] = [
        Color(red: 1.0, green: 0.84, blue: 0.0), // ゴールド
        Color(red: 0.0, green: 0.48, blue: 1.0), // 明るいブルー
        Color(red: 1.0, green: 0.41, blue: 0.71), // ピンク
        Color(red: 1.0, green: 0.92, blue: 0.23), // イエロー
        Color(red: 0.58, green: 0.29, blue: 0.95), // パープル
        Color(red: 0.0, green: 0.78, blue: 0.33), // グリーン
        Color(red: 1.0, green: 0.35, blue: 0.0), // オレンジ
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    Circle()
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size)
                        .position(piece.position)
                        .rotationEffect(.degrees(piece.rotation))
                        .opacity(piece.opacity)
                }
            }
            .onAppear {
                generateConfetti(geometry: geometry)
                startAnimation(geometry: geometry)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func generateConfetti(geometry: GeometryProxy) {
        let centerX = geometry.size.width / 2
        let startY = geometry.size.height * 0.5 // 画面中央から
        
        confettiPieces = (0..<60).map { _ in
            let angle = Double.random(in: -180...180) * .pi / 180
            let speed = CGFloat.random(in: 100...200)
            
            return ConfettiPiece(
                color: colors.randomElement() ?? .yellow,
                position: CGPoint(
                    x: centerX + CGFloat.random(in: -30...30),
                    y: startY
                ),
                rotation: Double.random(in: 0...360),
                opacity: 1.0,
                size: CGFloat.random(in: 8...14),
                velocity: CGPoint(
                    x: cos(angle) * speed,
                    y: sin(angle) * speed
                )
            )
        }
    }
    
    private func startAnimation(geometry: GeometryProxy) {
        withAnimation(.easeOut(duration: 2.5)) {
            for index in confettiPieces.indices {
                let piece = confettiPieces[index]
                
                // 速度ベクトルに基づいて位置を更新
                confettiPieces[index].position.x += piece.velocity.x
                confettiPieces[index].position.y += piece.velocity.y + CGFloat.random(in: 150...300)
                
                // 回転を追加
                confettiPieces[index].rotation += Double.random(in: 360...1080)
                
                // フェードアウト
                confettiPieces[index].opacity = 0.0
            }
        }
    }
}
