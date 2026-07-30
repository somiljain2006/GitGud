//
//  GitHubService.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import Foundation
import SwiftUI

struct GitHubService {
    private let graphQLService: GitHubGraphQLService
    
    init(graphQLService: GitHubGraphQLService = GitHubGraphQLService()) {
        self.graphQLService = graphQLService
    }
    
    func fetchUserAvatar(for username: String, token: String? = nil) async -> String? {
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: "")
        guard !cleanUsername.isEmpty,
              let url = URL(string: "https://api.github.com/users/\(cleanUsername)") else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = token, !token.isEmpty {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.addValue("GitGudApp", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }
            let decoded = try JSONDecoder().decode(GitHubUserResponse.self, from: data)
            return decoded.avatarUrl
        } catch {
            print("Error fetching avatar: \(error)")
            return nil
        }
    }
    
    func fetchRepositories(for username: String, token: String? = nil) async -> [PinnedRepo] {
        if let token = token, !token.isEmpty {
            if let pinned = await graphQLService.fetchPinnedRepositories(for: username, token: token), !pinned.isEmpty {
                return pinned
            }
        }
        
        return await fetchRecentReposREST(for: username)
    }
    
    func fetchRecentActivity(for username: String) async -> [ActivityItem] {
        guard let url = URL(string: "https://api.github.com/users/\(username)/events/public?per_page=4") else { return [] }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedEvents = try JSONDecoder().decode([GitHubEvent].self, from: data)
            
            return decodedEvents.map { event in
                let mappedType = mapEventType(event.type)
                return ActivityItem(
                    title: mappedType.title,
                    subtitle: event.repo.name,
                    timestamp: RelativeDateFormatter.relativeString(from: event.created_at),
                    systemImage: mappedType.icon,
                    tint: mappedType.color
                )
            }
        } catch {
            print("Error fetching events: \(error)")
            return []
        }
    }
    
    func fetchMyWork(for username: String, token: String? = nil) async -> [WorkItem] {
        let cleanUsername = username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
        
        guard !cleanUsername.isEmpty else { return [] }

        async let issues = fetchItems(qualifier: "is:issue", username: cleanUsername, token: token)
        async let pullRequests = fetchItems(qualifier: "is:pull-request", username: cleanUsername, token: token)

        let combinedItems = await (issues + pullRequests)

        let topItems = combinedItems
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(5)

        return topItems.map { item in
            let repoName = item.repositoryUrl
                .replacingOccurrences(of: "https://api.github.com/repos/", with: "")

            return WorkItem(
                repository: repoName,
                title: item.title,
                description: item.pullRequest != nil ? "Pull request • \(item.state.capitalized)" : "Issue • \(item.state.capitalized)",
                time: RelativeDateFormatter.relativeString(from: item.updatedAt),
                comments: item.comments,
                type: item.pullRequest != nil ? .pullRequest : .issue
            )
        }
    }
    
    func fetchQuickActions(for username: String, token: String?) async -> [QuickAction] {
        await graphQLService.fetchQuickActions(for: username, token: token)
    }
    
    private func fetchRecentReposREST(for username: String) async -> [PinnedRepo] {
        guard let url = URL(string: "https://api.github.com/users/\(username)/repos?sort=updated&per_page=4") else { return [] }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedRepos = try JSONDecoder().decode([GitHubRepo].self, from: data)
            
            return decodedRepos.map { repo in
                PinnedRepo(
                    name: repo.name,
                    description: repo.description ?? "No description provided.",
                    language: repo.language ?? "Unknown",
                    stars: StarFormatter.formatStars(repo.stargazers_count),
                    isPublic: !repo.private,
                    color: LanguageColor.color(for: repo.language)
                )
            }
        } catch {
            print("Error fetching repos via REST: \(error)")
            return []
        }
    }
    
    private func fetchItems(qualifier: String, username: String, token: String?) async -> [GitHubSearchItem] {
        var components = URLComponents(string: "https://api.github.com/search/issues")
        components?.queryItems = [
            URLQueryItem(name: "q", value: "involves:\(username) \(qualifier)"),
            URLQueryItem(name: "sort", value: "updated"),
            URLQueryItem(name: "order", value: "desc"),
            URLQueryItem(name: "per_page", value: "5")
        ]

        guard let url = components?.url else { return [] }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = token, !token.isEmpty {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.addValue("GitGudApp", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return []
            }

            let searchResponse = try JSONDecoder().decode(GitHubSearchResponse.self, from: data)
            return searchResponse.items
        } catch {
            print("Error fetching \(qualifier): \(error)")
            return []
        }
    }
    
    private func mapEventType(_ type: String) -> (title: String, icon: String, color: Color) {
        switch type {
        case "PushEvent": return ("Pushed code", "arrow.up.circle.fill", .cyan)
        case "PullRequestEvent": return ("Pull Request", "arrow.triangle.branch", .mint)
        case "IssuesEvent": return ("Issue updated", "exclamationmark.circle", .orange)
        case "WatchEvent": return ("Starred repository", "star.fill", .yellow)
        case "ForkEvent": return ("Forked repository", "arrow.triangle.merge", .blue)
        default: return ("Activity update", "bell.fill", .gray)
        }
    }
}
