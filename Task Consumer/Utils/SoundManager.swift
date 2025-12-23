//
//  SoundManager.swift
//  Agenda ToDo
//
//  Created by ryunosuke sato on 2025/12/21.
//

import AudioToolbox

class SoundManager {
    static let shared = SoundManager()
    
    private init() {}
    
    func play(_ type: TimerSoundType) {
        guard type != .none else { return }
        
        let soundID = type.systemSoundID
        AudioServicesPlaySystemSound(soundID)
    }
}

