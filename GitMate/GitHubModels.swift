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

struct GitHubEventRepo: Codable {
    let name: String
}

struct GitHubEvent: Codable {
    let id: String
    let type: String
    let created_at: String
    let repo: GitHubEventRepo
}

struct GitHubNotificationSubject: Codable {
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

struct GitHubNotificationRepo: Codable {
    let fullName: String

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
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

    typealias Subject = GitHubNotificationSubject
    typealias Repo = GitHubNotificationRepo
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

struct GitHubSearchPullRequestRef: Codable {
    let url: String?
    let mergedAt: String?

    enum CodingKeys: String, CodingKey {
        case url
        case mergedAt = "merged_at"
    }
}

struct GitHubSearchItem: Codable {
    let title: String
    let state: String
    let comments: Int
    let updatedAt: String
    let repositoryUrl: String
    let pullRequest: GitHubSearchPullRequestRef?
    let draft: Bool?
    let number: Int

    enum CodingKeys: String, CodingKey {
        case title, state, comments, draft, number
        case updatedAt = "updated_at"
        case repositoryUrl = "repository_url"
        case pullRequest = "pull_request"
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
    let head: PRBaseHead
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
        case head
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
    let ref: String?
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

    var id: String {
        filename
    }
}

struct GitHubFileContent: Codable {
    let name: String
    let path: String
    let sha: String
    let content: String
    let encoding: String

    var decodedContent: String? {
        guard encoding == "base64" else { return nil }
        let stripped = content.components(separatedBy: .whitespacesAndNewlines).joined()
        guard let data = Data(base64Encoded: stripped) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

enum FileUpdateError: Error, LocalizedError {
    case missingToken
    case unauthorized
    case forbidden
    case notFound
    case conflict
    case network(Error)
    case badResponse(Int)
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .missingToken: return "No GitHub token. Please sign in again."
        case .unauthorized: return "Authentication failed. Check your token."
        case .forbidden: return "You don't have permission to modify this repository."
        case .notFound: return "File or repository not found."
        case .conflict: return "The file was changed remotely. Reload the file before committing."
        case let .network(err): return "Network error: \(err.localizedDescription)"
        case let .badResponse(statusCode): return "Unexpected response from GitHub (HTTP \(statusCode))."
        case .encodingFailed: return "Failed to encode the file content."
        }
    }
}

struct PullRequestReference: Identifiable {
    var id: String {
        "\(owner)/\(repository)/\(number)"
    }

    let owner: String
    let repository: String
    let number: Int
}

struct FileUpdateRequest {
    let owner: String
    let repo: String
    let path: String
    let branch: String
    let sha: String
    let content: String
    let commitMessage: String
    let token: String?
}
