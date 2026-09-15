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
    var subtitle: String
    let imageName: String
    let tint: Color
}

struct MyDiscussion: Identifiable, Codable {
    let id: String
    let title: String
    let body: String?
    let url: String
    let repositoryName: String
    let createdAt: String
    let updatedAt: String
}

struct StarredRepository: Identifiable, Codable {
    let id: String
    let name: String
    let fullName: String
    let description: String?
    let url: String
    let stars: Int
    let language: String?
}
