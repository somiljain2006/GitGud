//
//  WorkItem.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import Foundation
import SwiftUI

struct WorkItem: Identifiable {
    let id = UUID()
    let repository: String
    let title: String
    let description: String
    let time: String
    let comments: Int
    let type: NotificationType
    var prState: PRState? = nil
    var pullRequestNumber: Int? = nil
    var owner: String? = nil
    var repo: String? = nil
}

enum PRState {
    case open, merged, closed, draft
    
    var color: Color {
        switch self {
        case .merged: return .purple
        case .closed: return .red
        case .draft: return .gray
        case .open: return .mint
        }
    }
    
    var title: String {
        switch self {
        case .merged: return "Merged"
        case .closed: return "Closed"
        case .draft: return "Draft"
        case .open: return "Open"
        }
    }
}
