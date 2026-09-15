//
//  ActivityItem.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import SwiftUI

struct ActivityItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let timestamp: String
    let systemImage: String
    let tint: Color
}
