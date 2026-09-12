//
//  AIChatMessage.swift
//  GitMate
//
//  Created by somil jain on 12/09/26.
//

import Foundation

struct AIChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String

    enum Role {
        case user
        case assistant
    }
}
