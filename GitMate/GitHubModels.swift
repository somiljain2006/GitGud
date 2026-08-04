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
    let updatedAt: String
    let lastReadAt: String?
    let subject: Subject
    let repository: Repo
    let url: String?
    let subscriptionUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case unread
        case reason
        case updatedAt = "updated_at"
        case lastReadAt = "last_read_at"
        case subject
        case repository
        case url
        case subscriptionUrl = "subscription_url"
    }

    struct Subject: Codable {
        let title: String
        let url: String?
        let latestCommentUrl: String?
        let type: String
        let state: String?
        
        enum CodingKeys: String, CodingKey {
            case title
            case url
            case latestCommentUrl = "latest_comment_url"
            case type
            case state
        }
    }

    struct Repo: Codable {
        let fullName: String

        enum CodingKeys: String, CodingKey {
            case fullName = "full_name"
        }
    }
}

struct GitHubAPIErrorResponse: Codable {
    let message: String
    let documentationURL: String?
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case message
        case documentationURL = "documentation_url"
        case status
    }
}

struct GitHubAuthenticatedUser: Codable {
    let login: String
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
    let draft: Bool?
    
    enum CodingKeys: String, CodingKey {
        case title, state, comments, draft
        case updatedAt = "updated_at"
        case repositoryUrl = "repository_url"
        case pullRequest = "pull_request"
    }

    struct PullRequestRef: Codable {
        let url: String?
        let mergedAt: String?
        
        enum CodingKeys: String, CodingKey {
            case url
            case mergedAt = "merged_at"
        }
    }
}
