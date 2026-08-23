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
    let stargazersCount: Int
    let forksCount: Int
    let `private`: Bool
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case language
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
        case `private`
        case updatedAt = "updated_at"
    }
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
    let number: Int
    
    enum CodingKeys: String, CodingKey {
        case title, state, comments, draft, number
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

struct PullRequestDetail: Codable, Identifiable {
    let id: Int
    let number: Int
    let title: String
    let body: String?
    let state: String
    let draft: Bool?
    let user: GitHubUser
    let createdAt: String
    let updatedAt: String
    let mergedAt: String?
    let closedAt: String?
    let additions: Int
    let deletions: Int
    let changedFiles: Int
    let commits: Int
    let comments: Int
    let reviewComments: Int
    let base: PRBaseHead
    let htmlUrl: String

    enum CodingKeys: String, CodingKey {
        case id, number, title, body, state, draft, user, additions, deletions, commits, comments
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case mergedAt = "merged_at"
        case closedAt = "closed_at"
        case changedFiles = "changed_files"
        case reviewComments = "review_comments"
        case base
        case htmlUrl = "html_url"
    }
}

struct GitHubUser: Codable {
    let login: String
    let avatarUrl: String
    
    enum CodingKeys: String, CodingKey {
        case login
        case avatarUrl = "avatar_url"
    }
}

struct PRBaseHead: Codable {
    let repo: PRRepo?
}

struct PRRepo: Codable {
    let name: String
    let owner: GitHubUser
}

struct PullRequestFile: Codable, Identifiable {
    let filename: String
    let status: String
    let additions: Int
    let deletions: Int
    let changes: Int
    let patch: String?
    
    var id: String { filename }
}

struct PullRequestReference: Identifiable {
    var id: String { "\(owner)/\(repository)/\(number)" }
    let owner: String
    let repository: String
    let number: Int
}
