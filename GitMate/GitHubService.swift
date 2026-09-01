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

        let combinedItems = await(issues + pullRequests)

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

    func fetchIssueDetail(
        owner: String,
        repo: String,
        number: Int,
        token: String?
    ) async -> MyIssue? {
        guard let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/issues/\(number)") else { return nil }

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

            struct RESTIssue: Codable {
                let id: Int
                let number: Int
                let title: String
                let state: String
                let body: String?
                let html_url: String
                let created_at: String
                let updated_at: String
            }

            let restIssue = try JSONDecoder().decode(RESTIssue.self, from: data)
            return MyIssue(
                id: restIssue.id,
                number: restIssue.number,
                title: restIssue.title,
                state: restIssue.state,
                body: restIssue.body,
                htmlURL: restIssue.html_url,
                repositoryName: "\(owner)/\(repo)",
                createdAt: restIssue.created_at,
                updatedAt: restIssue.updated_at
            )
        } catch {
            print("Error fetching Issue detail: \(error)")
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

    func updateFile(req: FileUpdateRequest) async -> Result<Void, FileUpdateError> {
        guard let token = req.token, !token.isEmpty else { return .failure(.missingToken) }

        guard let contentData = req.content.data(using: .utf8) else { return .failure(.encodingFailed) }
        let base64Content = contentData.base64EncodedString()

        let encodedPath = req.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? req.path
        guard let url = URL(string: "https://api.github.com/repos/\(req.owner)/\(req.repo)/contents/\(encodedPath)") else {
            return .failure(.badResponse(0))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.addValue("GitGudApp", forHTTPHeaderField: "User-Agent")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "message": req.commitMessage,
            "content": base64Content,
            "sha": req.sha,
            "branch": req.branch,
        ]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return .failure(.encodingFailed)
        }

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return handleFileUpdateResponse(response)
        } catch {
            return .failure(.network(error))
        }
    }

    func fetchPullRequestCommits(
        owner: String,
        repo: String,
        number: Int,
        token: String?
    ) async -> [PullRequestCommit] {
        guard let url = URL(
            string: "https://api.github.com/repos/\(owner)/\(repo)/pulls/\(number)/commits"
        ) else {
            return []
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token, !token.isEmpty {
            request.addValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )
        }

        request.addValue(
            "application/vnd.github+json",
            forHTTPHeaderField: "Accept"
        )

        request.addValue(
            "GitMateApp",
            forHTTPHeaderField: "User-Agent"
        )

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let response = response as? HTTPURLResponse,
                  response.statusCode == 200
            else {
                return []
            }

            return try JSONDecoder().decode(
                [PullRequestCommit].self,
                from: data
            )
        } catch {
            print("Error fetching PR commits: \(error)")
            return []
        }
    }

    func fetchPullRequestReviewComments(
        owner: String,
        repo: String,
        number: Int,
        token: String?
    ) async -> [PullRequestReviewComment] {
        await graphQLService.fetchPullRequestReviewComments(
            owner: owner,
            repo: repo,
            number: number,
            token: token
        )
    }

    func setReviewThreadResolved(
        threadID: String,
        resolved: Bool,
        token: String?
    ) async -> Bool {
        await graphQLService.setReviewThreadResolved(
            threadID: threadID,
            resolved: resolved,
            token: token
        )
    }

    func replyToPullRequestReviewComment(
        request: CommentReplyRequest
    ) async -> PullRequestReviewComment? {
        guard let url = URL(
            string: "https://api.github.com/repos/\(request.owner)/\(request.repo)/pulls/\(request.pullNumber)/comments/\(request.commentID)/replies"
        ) else {
            return nil
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        urlRequest.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("2026-03-10", forHTTPHeaderField: "X-GitHub-Api-Version")

        if let token = request.token, !token.isEmpty {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = [
            "body": request.body,
        ]

        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: payload)

            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 201
            else {
                return nil
            }

            return try JSONDecoder().decode(
                PullRequestReviewComment.self,
                from: data
            )
        } catch {
            print("Error replying to review comment: \(error)")
            return nil
        }
    }

    func postIssueComment(
        owner: String,
        repo: String,
        issueNumber: Int,
        body: String,
        token: String?
    ) async -> Bool {
        guard let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/issues/\(issueNumber)/comments") else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("GitGudApp", forHTTPHeaderField: "User-Agent")

        if let token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: ["body": body])
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else { return false }

            guard httpResponse.statusCode == 201 else {
                print("Failed to post comment. Status: \(httpResponse.statusCode)")
                if let responseBody = String(data: data, encoding: .utf8) {
                    print("GitHub response: \(responseBody)")
                }
                return false
            }

            return true
        } catch {
            print("Error posting issue comment: \(error)")
            return false
        }
    }

    func fetchIssueComments(
        owner: String,
        repo: String,
        issueNumber: Int,
        token: String?
    ) async -> [IssueComment] {
        guard let url = URL(
            string: "https://api.github.com/repos/\(owner)/\(repo)/issues/\(issueNumber)/comments?per_page=100"
        ) else {
            return []
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token, !token.isEmpty {
            request.setValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )
        }

        request.setValue(
            "application/vnd.github+json",
            forHTTPHeaderField: "Accept"
        )

        request.setValue(
            "GitGudApp",
            forHTTPHeaderField: "User-Agent"
        )

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                return []
            }

            guard (200 ... 299).contains(httpResponse.statusCode) else {
                print(
                    "Failed to fetch comments. Status: \(httpResponse.statusCode)"
                )

                if let responseBody = String(data: data, encoding: .utf8) {
                    print("GitHub response: \(responseBody)")
                }

                return []
            }

            return try JSONDecoder().decode(
                [IssueComment].self,
                from: data
            )
        } catch {
            print("Error fetching issue comments: \(error)")
            return []
        }
    }

    private func handleFileUpdateResponse(_ response: URLResponse?) -> Result<Void, FileUpdateError> {
        guard let httpResponse = response as? HTTPURLResponse else { return .failure(.badResponse(0)) }
        switch httpResponse.statusCode {
        case 200, 201: return .success(())
        case 401: return .failure(.unauthorized)
        case 403: return .failure(.forbidden)
        case 404: return .failure(.notFound)
        case 409: return .failure(.conflict)
        default: return .failure(.badResponse(httpResponse.statusCode))
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
            URLQueryItem(name: "per_page", value: "5"),
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

    struct EventTypeDisplay {
        let title: String
        let icon: String
        let color: Color
    }

    private func mapEventType(_ type: String) -> EventTypeDisplay {
        switch type {
        case "PushEvent": return EventTypeDisplay(title: "Pushed code", icon: "arrow.up.circle.fill", color: .cyan)
        case "PullRequestEvent": return EventTypeDisplay(title: "Pull Request", icon: "arrow.triangle.branch", color: .mint)
        case "IssuesEvent": return EventTypeDisplay(title: "Issue updated", icon: "exclamationmark.circle", color: .orange)
        case "WatchEvent": return EventTypeDisplay(title: "Starred repository", icon: "star.fill", color: .yellow)
        case "ForkEvent": return EventTypeDisplay(title: "Forked repository", icon: "arrow.triangle.merge", color: .blue)
        default: return EventTypeDisplay(title: "Activity update", icon: "bell.fill", color: .gray)
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
    let repository: GitHubIssueSearchItemRepository
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
}

struct GitHubIssueSearchItemRepository: Codable {
    let fullName: String

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
    }
}
