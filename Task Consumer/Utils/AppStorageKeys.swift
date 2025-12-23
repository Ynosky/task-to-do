//
//  AppStorageKeys.swift
//  Agenda ToDo
//
//  Created by ryunosuke sato on 2025/12/21.
//

import Foundation
import AudioToolbox

// MARK: - Timer Sound Type

enum TimerSoundType: String, CaseIterable, Identifiable, Codable {
    case none
    case chime
    case alarm
    case bell
    case bird
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .none:
            return LanguageManager.shared.language == .japanese ? "なし" : "None"
        case .chime:
            return LanguageManager.shared.language == .japanese ? "チャイム" : "Chime"
        case .alarm:
            return LanguageManager.shared.language == .japanese ? "アラーム" : "Alarm"
        case .bell:
            return LanguageManager.shared.language == .japanese ? "ベル" : "Bell"
        case .bird:
            return LanguageManager.shared.language == .japanese ? "鳥の声" : "Bird"
        }
    }
    
    var systemSoundID: SystemSoundID {
        switch self {
        case .none:
            return 0
        case .chime:
            return 1005 // Chime
        case .alarm:
            return 1054 // Alarm
        case .bell:
            return 1022 // Bell
        case .bird:
            return 1014 // Bird
        }
    }
}

// MARK: - Timer Haptic Type

enum TimerHapticType: String, CaseIterable, Identifiable, Codable {
    case none
    case light
    case medium
    case heavy
    case long
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .none:
            return LanguageManager.shared.language == .japanese ? "なし" : "None"
        case .light:
            return LanguageManager.shared.language == .japanese ? "控えめ" : "Light"
        case .medium:
            return LanguageManager.shared.language == .japanese ? "普通" : "Medium"
        case .heavy:
            return LanguageManager.shared.language == .japanese ? "強い" : "Heavy"
        case .long:
            return LanguageManager.shared.language == .japanese ? "長め" : "Long"
        }
    }
}

