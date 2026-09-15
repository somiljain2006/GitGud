//
//  StandardRepo.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import Foundation

struct StandardRepo: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let language: String?
}
