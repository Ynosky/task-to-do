//
//  AppTheme.swift
//  Agenda ToDo
//
//  Created by ryunosuke sato on 2025/12/21.
//

import SwiftUI

/// アプリのテーマカラー定義
struct AppTheme {
    // MARK: - Deep Theme (Dark Mode)
    struct Deep {
        // 背景: 深い紺色（#020617）
        static let background = Color(hex: "#020617")
        static let backgroundSecondary = Color(hex: "#0a1628")
        
        // アクセント: シアン（cyan-400相当）
        static let accent = Color(hex: "#22d3ee") // cyan-400
        static let accentDim = Color(hex: "#22d3ee").opacity(0.6)
        
        // テキスト
        static let textPrimary = Color.white.opacity(0.95)
        static let textSecondary = Color.white.opacity(0.6)
        static let textTertiary = Color.white.opacity(0.3)
        
        // 完了タスク（極限まで不透明度を下げる）
        static let completed = Color.white.opacity(0.1)
        
        // カード背景
        static let cardBackground = Color(hex: "#0f1b2e").opacity(0.6)
    }
    
    // MARK: - Paper Theme (Light Mode)
    struct Paper {
        // 背景: セピア調のクリーム色（#f4f1ea）
        static let background = Color(hex: "#f4f1ea")
        static let backgroundSecondary = Color(hex: "#ede8df")
        
        // アクセント: 墨のような黒（black/80）
        static let accent = Color.black.opacity(0.8)
        static let accentDim = Color.black.opacity(0.5)
        
        // テキスト
        static let textPrimary = Color.black.opacity(0.85)
        static let textSecondary = Color.black.opacity(0.6)
        static let textTertiary = Color.black.opacity(0.4)
        
        // 完了タスク（インクが乾いて薄くなった表現）
        static let completed = Color.black.opacity(0.2)
        
        // カード背景
        static let cardBackground = Color.white.opacity(0.7)
    }
    
    // MARK: - 環境に応じたカラー取得
    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Deep.background : Paper.background
    }
    
    static func backgroundSecondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Deep.backgroundSecondary : Paper.backgroundSecondary
    }
    
    static func accent(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Deep.accent : Paper.accent
    }
    
    static func textPrimary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Deep.textPrimary : Paper.textPrimary
    }
    
    static func textSecondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Deep.textSecondary : Paper.textSecondary
    }
    
    static func textTertiary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Deep.textTertiary : Paper.textTertiary
    }
    
    static func completed(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Deep.completed : Paper.completed
    }
    
    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Deep.cardBackground : Paper.cardBackground
    }
}

// MARK: - Color Extension (Hex Support)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extension (Theme-aware Background)

extension View {
    /// テーマに応じたグラデーション背景を適用
    func themeBackground(colorScheme: ColorScheme) -> some View {
        self.background(
            ZStack {
                if colorScheme == .dark {
                    // Deep: 放射状グラデーション
                    RadialGradient(
                        colors: [
                            AppTheme.Deep.background,
                            AppTheme.Deep.backgroundSecondary,
                            AppTheme.Deep.background
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 800
                    )
                } else {
                    // Paper: セピアクリーム背景
                    AppTheme.Paper.background
                }
            }
            .ignoresSafeArea()
        )
    }
}

