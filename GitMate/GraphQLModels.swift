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
