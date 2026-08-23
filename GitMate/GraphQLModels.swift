//
//  GraphQLModels.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import Foundation

struct GraphQLPinnedResponse: Codable {
    let data: GraphQLData?

    struct GraphQLData: Codable {
        let user: GraphQLUser?
    }

    struct GraphQLUser: Codable {
        let pinnedItems: GraphQLPinnedItems?
    }

    struct GraphQLPinnedItems: Codable {
        let nodes: [GraphQLRepoNode]?
    }

    struct GraphQLRepoNode: Codable {
        let name: String
        let description: String?
        let isPrivate: Bool?
        let stargazerCount: Int?
        let primaryLanguage: LanguageNode?
        let owner: OwnerNode?

        struct LanguageNode: Codable {
            let name: String
        }

        struct OwnerNode: Codable {
            let login: String
        }
    }
}

struct GraphQLStatsResponse: Codable {
    let data: StatsData?
    
    struct StatsData: Codable {
        let user: StatsUser?
    }
    
    struct StatsUser: Codable {
        let issues: CountNode?
        let pullRequests: CountNode?
        let starredRepositories: CountNode?
        let repositoryDiscussions: CountNode?
    }
    
    struct CountNode: Codable {
        let totalCount: Int
    }
}

struct GraphQLMyIssuesResponse: Codable {
    let data: GraphQLMyIssuesData?
}

struct GraphQLMyIssuesData: Codable {
    let user: GraphQLMyIssuesUser?
}

struct GraphQLMyIssuesUser: Codable {
    let issues: GraphQLMyIssuesConnection?
}

struct GraphQLMyIssuesConnection: Codable {
    let nodes: [GraphQLMyIssueNode]?
}

struct GraphQLMyIssueNode: Codable {
    let number: Int
    let title: String
    let state: String
    let bodyText: String?
    let url: String
    let repository: GraphQLMyIssueRepository
    let createdAt: String
    let updatedAt: String
}

struct GraphQLMyIssueRepository: Codable {
    let nameWithOwner: String
}

struct GraphQLMyPullRequestsResponse: Codable {
    let data: GraphQLMyPullRequestsData?
}

struct GraphQLMyPullRequestsData: Codable {
    let user: GraphQLMyPullRequestsUser?
}

struct GraphQLMyPullRequestsUser: Codable {
    let pullRequests: GraphQLMyPullRequestsConnection?
}

struct GraphQLMyPullRequestsConnection: Codable {
    let nodes: [GraphQLMyPullRequestNode]?
}

struct GraphQLMyPullRequestNode: Codable {
    let number: Int
    let title: String
    let state: String
    let bodyText: String?
    let url: String
    let repository: GraphQLMyPullRequestRepository
    let createdAt: String
    let updatedAt: String
}

struct GraphQLMyPullRequestRepository: Codable {
    let nameWithOwner: String
}

struct GraphQLMyDiscussionsResponse: Codable {
    let data: GraphQLMyDiscussionsData?
}

struct GraphQLMyDiscussionsData: Codable {
    let user: GraphQLMyDiscussionsUser?
}

struct GraphQLMyDiscussionsUser: Codable {
    let repositoryDiscussions: GraphQLMyDiscussionsConnection?
}

struct GraphQLMyDiscussionsConnection: Codable {
    let nodes: [GraphQLMyDiscussionNode]?
}

struct GraphQLMyDiscussionNode: Codable {
    let id: String
    let title: String
    let body: String?
    let url: String
    let repository: GraphQLDiscussionRepository
    let createdAt: String
    let updatedAt: String
}

struct GraphQLDiscussionRepository: Codable {
    let nameWithOwner: String
}

struct GraphQLStarredRepositoriesResponse: Codable {
    let data: GraphQLStarredRepositoriesData?
}

struct GraphQLStarredRepositoriesData: Codable {
    let user: GraphQLStarredRepositoriesUser?
}

struct GraphQLStarredRepositoriesUser: Codable {
    let starredRepositories: GraphQLStarredRepositoriesConnection?
}

struct GraphQLStarredRepositoriesConnection: Codable {
    let nodes: [GraphQLStarredRepositoryNode]?
}

struct GraphQLStarredRepositoryNode: Codable {
    let id: String
    let name: String
    let nameWithOwner: String
    let description: String?
    let url: String
    let stargazerCount: Int
    let primaryLanguage: GraphQLStarredLanguage?
}

struct GraphQLStarredLanguage: Codable {
    let name: String
}
