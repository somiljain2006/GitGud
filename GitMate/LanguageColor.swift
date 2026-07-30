//
//  LanguageColor.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import SwiftUI

enum LanguageColor {
    static func color(for language: String?) -> Color {
        switch language?.lowercased() {
        case "swift": return .orange
        case "rust": return .brown
        case "typescript", "javascript": return .yellow
        case "python": return .blue
        case "java": return .red
        default: return .cyan
        }
    }
}
