//
//  GitHubService.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import Foundation
import SwiftUI

// swiftlint:disable type_body_length
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

            let prState: PRState?
            if let pr = item.pullRequest {
                if item.draft == true {
                    prState = .draft
                } else if pr.mergedAt != nil {
                    prState = .merged
                } else if item.state == "closed" {
                    prState = .closed
                } else {
                    prState = .open
                }
            } else {
                prState = nil
            }

            let descriptionText: String
            if let state = prState {
                descriptionText = "Pull request • \(state.title)"
            } else {
                descriptionText = "Issue • \(item.state.capitalized)"
            }

            let parts = repoName.split(separator: "/")
            let ownerStr = !parts.isEmpty ? String(parts[0]) : nil
            let repoStr = parts.count > 1 ? String(parts[1]) : nil

            return WorkItem(
                repository: repoName,
                title: item.title,
                description: descriptionText,
                time: RelativeDateFormatter.relativeString(from: item.updatedAt),
                comments: item.comments,
                type: item.pullRequest != nil ? .pullRequest : .issue,
                prState: prState,
                pullRequestNumber: item.pullRequest != nil ? item.number : nil,
                owner: ownerStr,
                repo: repoStr
            )
        }
    }
    
    func fetchQuickActions(for username: String, token: String?) async -> [QuickAction] {
        await graphQLService.fetchQuickActions(for: username, token: token)
    }
    
    func fetchUserReadme(for username: String, token: String? = nil) async -> String? {
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: "")
        guard !cleanUsername.isEmpty,
              let url = URL(string: "https://api.github.com/repos/\(cleanUsername)/\(cleanUsername)/readme") else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = token, !token.isEmpty {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.addValue("application/vnd.github.html", forHTTPHeaderField: "Accept")
        request.addValue("GitGudApp", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }
            return String(data: data, encoding: .utf8)
        } catch {
            print("Error fetching README: \(error)")
            return nil
        }
    }
    
    func fetchUserStats(for username: String, token: String? = nil) async -> (followers: Int, following: Int)? {
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: "")
        guard !cleanUsername.isEmpty,
              let url = URL(string: "https://api.github.com/users/\(cleanUsername)") else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = token, !token.isEmpty {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }
            
            struct StatsResponse: Codable {
                let followers: Int
                let following: Int
            }
            
            let decoded = try JSONDecoder().decode(StatsResponse.self, from: data)
            return (decoded.followers, decoded.following)
        } catch {
            print("Error fetching user stats: \(error)")
            return nil
        }
    }
    
    func fetchMyIssues(
        for username: String,
        token: String?
    ) async -> [MyIssue] {
        return await graphQLService.fetchMyIssues(for: username, token: token)
    }
    
    func fetchMyPullRequests(
        for username: String,
        token: String?
    ) async -> [MyPullRequest] {
        return await graphQLService.fetchMyPullRequests(for: username, token: token)
    }
    
    func fetchMyDiscussions(
        for username: String,
        token: String?
    ) async -> [MyDiscussion] {
        return await graphQLService.fetchMyDiscussions(
            for: username,
            token: token
        )
    }
    
    func fetchStarredRepositories(
        for username: String,
        token: String?
    ) async -> [StarredRepository] {
        return await graphQLService.fetchStarredRepositories(
            for: username,
            token: token
        )
    }
    
    func fetchPullRequestDetail(
        owner: String,
        repo: String,
        number: Int,
        token: String?
    ) async -> PullRequestDetail? {
        guard let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/pulls/\(number)") else { return nil }
        
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
            return try JSONDecoder().decode(PullRequestDetail.self, from: data)
        } catch {
            print("Error fetching PR detail: \(error)")
            return nil
        }
    }
    
    func fetchPullRequestFiles(
        owner: String,
        repo: String,
        number: Int,
        token: String?
    ) async -> [PullRequestFile] {
        guard let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/pulls/\(number)/files") else { return [] }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = token, !token.isEmpty {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.addValue("GitGudApp", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return [] }
            return try JSONDecoder().decode([PullRequestFile].self, from: data)
        } catch {
            print("Error fetching PR files: \(error)")
            return []
        }
    }

    func fetchFileContent(
        owner: String,
        repo: String,
        path: String,
        branch: String,
        token: String?
    ) async -> GitHubFileContent? {
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        guard var components = URLComponents(string: "https://api.github.com/repos/\(owner)/\(repo)/contents/\(encodedPath)") else { return nil }
        components.queryItems = [URLQueryItem(name: "ref", value: branch)]
        guard let url = components.url else { return nil }

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
            return try JSONDecoder().decode(GitHubFileContent.self, from: data)
        } catch {
            print("Error fetching file content: \(error)")
            return nil
        }
    }

    func updateFile(
        owner: String,
        repo: String,
        path: String,
        branch: String,
        sha: String,
        content: String,
        commitMessage: String,
        token: String?
    ) async -> Result<Void, FileUpdateError> {
        guard let token = token, !token.isEmpty else { return .failure(.missingToken) }

        guard let contentData = content.data(using: .utf8) else { return .failure(.encodingFailed) }
        let base64Content = contentData.base64EncodedString()

        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        guard let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/contents/\(encodedPath)") else {
            return .failure(.badResponse(0))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.addValue("GitGudApp", forHTTPHeaderField: "User-Agent")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "message": commitMessage,
            "content": base64Content,
            "sha": sha,
            "branch": branch
        ]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return .failure(.encodingFailed)
        }

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return .failure(.badResponse(0)) }
            switch httpResponse.statusCode {
            case 200, 201: return .success(())
            case 401: return .failure(.unauthorized)
            case 403: return .failure(.forbidden)
            case 404: return .failure(.notFound)
            case 409: return .failure(.conflict)
            default:  return .failure(.badResponse(httpResponse.statusCode))
            }
        } catch {
            return .failure(.network(error))
        }
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
                    stars: StarFormatter.formatStars(repo.stargazersCount),
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

struct GitHubIssueSearchResponse: Codable {
    let items: [GitHubIssueSearchItem]
}

struct GitHubIssueSearchItem: Codable {
    let id: Int
    let number: Int
    let title: String
    let state: String
    let body: String?
    let htmlURL: String
    let repository: Repository
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case number
        case title
        case state
        case body
        case htmlURL = "html_url"
        case repository
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    struct Repository: Codable {
        let fullName: String

        enum CodingKeys: String, CodingKey {
            case fullName = "full_name"
        }
    }
}
