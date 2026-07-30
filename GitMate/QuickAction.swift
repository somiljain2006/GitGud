//
//  QuickAction.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import SwiftUI

struct QuickAction: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageName: String
    let tint: Color
}
