//
//  NotificationType.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import SwiftUI

enum NotificationType {
    case pullRequest, issue, review, comment, ciFailed, ciPassed, discussion, release
    
    var icon: String {
        switch self {
        case .pullRequest: return "arrow.triangle.branch"
        case .issue: return "exclamationmark.circle"
        case .review: return "checkmark.circle"
        case .comment: return "message"
        case .ciFailed: return "xmark.octagon.fill"
        case .ciPassed: return "checkmark.seal.fill"
        case .discussion: return "bubble.left.and.bubble.right.fill"
        case .release: return "tag.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .pullRequest: return .green
        case .issue: return .orange
        case .review: return .cyan
        case .comment: return .blue
        case .ciFailed: return .red
        case .ciPassed: return .green
        case .discussion: return .purple
        case .release: return .pink
        }
    }
}
