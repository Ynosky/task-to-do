//
//  LanguageManager.swift
//  Task ToDo
//
//  Created by ryunosuke sato on 2025/12/21.
//

import SwiftUI
import Combine

enum AppLanguage: String, Codable {
    case japanese = "ja"
    case english = "en"
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "app_language")
            objectWillChange.send()
        }
    }
    
    private init() {
        // UserDefaultsから読み込み
        if let savedLanguage = UserDefaults.standard.string(forKey: "app_language"),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.language = language
        } else {
            self.language = .japanese
        }
    }
}

