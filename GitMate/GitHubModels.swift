//
//  GitHubModels.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import Foundation

struct GitHubUserResponse: Codable {
    let avatarUrl: String

    enum CodingKeys: String, CodingKey {
        case avatarUrl = "avatar_url"
    }
}

struct GitHubRepo: Codable {
    let name: String
    let description: String?
    let language: String?
    let stargazers_count: Int
    let `private`: Bool
}

struct GitHubEvent: Codable {
    let id: String
    let type: String
    let created_at: String
    let repo: EventRepo
    
    struct EventRepo: Codable {
        let name: String
    }
}

struct GitHubNotification: Codable {
    let id: String
    let unread: Bool
    let reason: String
    let updated_at: String
    let subject: Subject
    let repository: Repo
    
    struct Subject: Codable {
        let title: String
        let url: String
        let type: String
    }
    
    struct Repo: Codable {
        let full_name: String
    }
}

struct GitHubSearchResponse: Codable {
    let items: [GitHubSearchItem]
}

struct GitHubSearchItem: Codable {
    let title: String
    let state: String
    let comments: Int
    let updatedAt: String
    let repositoryUrl: String
    let pullRequest: PullRequestRef?
    
    enum CodingKeys: String, CodingKey {
        case title, state, comments
        case updatedAt = "updated_at"
        case repositoryUrl = "repository_url"
        case pullRequest = "pull_request"
    }

    struct PullRequestRef: Codable {
        let url: String?
    }
}
