//
//  HapticManager.swift
//  Agenda ToDo
//
//  Created by ryunosuke sato on 2025/12/21.
//

import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // 成功、警告、エラーなどの通知系
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    // UI操作の衝撃系 (light, medium, heavy, rigid, soft)
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    // タイマー完了時の振動（TimerHapticType対応）
    func play(_ type: TimerHapticType) {
        guard type != .none else { return }
        
        switch type {
        case .none:
            break
        case .light:
            impact(style: .light)
        case .medium:
            impact(style: .medium)
        case .heavy:
            impact(style: .heavy)
        case .long:
            // 長めの振動: 1秒間に複数回インパクト
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                generator.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                generator.impactOccurred()
            }
        }
    }
}

