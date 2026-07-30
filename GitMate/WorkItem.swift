//
//  WorkItem.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import Foundation

struct WorkItem: Identifiable {
    let id = UUID()
    let repository: String
    let title: String
    let description: String
    let time: String
    let comments: Int
    let type: NotificationType
}
