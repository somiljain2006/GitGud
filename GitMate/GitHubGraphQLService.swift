//
//  GitHubGraphQLService.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import Foundation
import SwiftUI

struct GitHubGraphQLService {
    
    func fetchPinnedRepositories(for username: String, token: String) async -> [PinnedRepo]? {
        guard let url = URL(string: "https://api.github.com/graphql") else { return nil }

        let query = """
        {
          user(login: "\(username)") {
            pinnedItems(first: 4, types: REPOSITORY) {
              nodes {
                ... on Repository {
                  name
                  description
                  isPrivate
                  stargazerCount
                  primaryLanguage {
                    name
                  }
                }
              }
            }
          }
        }
        """

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["query": query]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        request.httpBody = httpBody

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            let decoded = try JSONDecoder().decode(GraphQLPinnedResponse.self, from: data)
            guard let nodes = decoded.data?.user?.pinnedItems?.nodes else { return nil }

            return nodes.map { repo in
                PinnedRepo(
                    name: repo.name,
                    description: repo.description ?? "No description provided.",
                    language: repo.primaryLanguage?.name ?? "Unknown",
                    stars: StarFormatter.formatStars(repo.stargazerCount),
                    isPublic: !repo.isPrivate,
                    color: LanguageColor.color(for: repo.primaryLanguage?.name)
                )
            }
        } catch {
            print("GraphQL Pinned Repos error: \(error)")
            return nil
        }
    }
    
    func fetchQuickActions(for username: String, token: String?) async -> [QuickAction] {
        let fallback: [QuickAction] = [
            .init(title: "Issues", subtitle: "0 opened", imageName: "issue_icon", tint: .cyan),
            .init(title: "Pull Requests", subtitle: "0 opened", imageName: "pull_request_icon", tint: .mint),
            .init(title: "Discussions", subtitle: "0 started", imageName: "discussion_icon", tint: .blue),
            .init(title: "Starred", subtitle: "0 repos", imageName: "starred_icon", tint: .indigo)
        ]
        
        let cleanUsername = username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
        
        guard let token = token, !token.isEmpty, !cleanUsername.isEmpty,
              let url = URL(string: "https://api.github.com/graphql") else {
            return fallback
        }
        
        let query = """
        {
          user(login: "\(cleanUsername)") {
            issues(states: OPEN) { totalCount }
            pullRequests(states: OPEN) { totalCount }
            starredRepositories { totalCount }
            repositoryDiscussions { totalCount }
          }
        }
        """
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["query": query]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else { return fallback }
        request.httpBody = httpBody
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return fallback }
            
            let decoded = try JSONDecoder().decode(GraphQLStatsResponse.self, from: data)
            guard let stats = decoded.data?.user else { return fallback }
            
            return [
                .init(title: "Issues", subtitle: "\(stats.issues?.totalCount ?? 0) opened", imageName: "issue_icon", tint: .cyan),
                .init(title: "Pull Requests", subtitle: "\(stats.pullRequests?.totalCount ?? 0) opened", imageName: "pull_request_icon", tint: .mint),
                .init(title: "Discussions", subtitle: "\(stats.repositoryDiscussions?.totalCount ?? 0) started", imageName: "discussion_icon", tint: .blue),
                .init(title: "Starred", subtitle: "\(stats.starredRepositories?.totalCount ?? 0) repos", imageName: "starred_icon", tint: .indigo)
            ]
        } catch {
            print("GraphQL Quick Actions error: \(error)")
            return fallback
        }
    }
}
