//
//  PinnedRepo.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import SwiftUI

struct PinnedRepo: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let language: String
    let stars: String
    let isPublic: Bool
    let color: Color
}
