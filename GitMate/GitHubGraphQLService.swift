//
//  GitHubGraphQLService.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import Foundation
import SwiftUI

struct GitHubGraphQLService {
    private func executeGraphQL<T: Decodable>(query: String, token: String?) async throws -> T {
        guard let token = token, !token.isEmpty,
              let url = URL(string: "https://api.github.com/graphql")
        else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.addValue("GitMateApp", forHTTPHeaderField: "User-Agent")

        let body: [String: Any] = ["query": query]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    private func clean(_ username: String) -> String {
        username.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: "")
    }

    func fetchPinnedRepositories(for username: String, token: String) async -> [PinnedRepo]? {
        let query = """
        { user(login: "\(username)") { pinnedItems(first: 4, types: REPOSITORY) { nodes { ... on Repository {
        name description isPrivate stargazerCount owner { login } primaryLanguage { name } } } } } }
        """
        do {
            let decoded: GraphQLPinnedResponse = try await executeGraphQL(query: query, token: token)
            guard let nodes = decoded.data?.user?.pinnedItems?.nodes else { return nil }
            return nodes.map { repo in
                PinnedRepo(
                    name: repo.name,
                    description: repo.description ?? "No description provided.",
                    language: repo.primaryLanguage?.name ?? "Unknown",
                    stars: StarFormatter.formatStars(repo.stargazerCount ?? 0),
                    isPublic: !(repo.isPrivate ?? false),
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
            .init(title: "Starred", subtitle: "0 repos", imageName: "starred_icon", tint: .indigo),
        ]

        let user = clean(username)
        guard !user.isEmpty else { return fallback }

        let query = """
        { user(login: "\(user)") { issues(states: OPEN, filterBy: { createdBy: "\(user)" }) { totalCount }
        pullRequests(states: OPEN) { totalCount } starredRepositories { totalCount } repositoryDiscussions { totalCount } } }
        """

        do {
            let decoded: GraphQLStatsResponse = try await executeGraphQL(query: query, token: token)
            guard let stats = decoded.data?.user else { return fallback }
            return [
                .init(title: "Issues", subtitle: "\(stats.issues?.totalCount ?? 0) opened", imageName: "issue_icon", tint: .cyan),
                .init(title: "Pull Requests", subtitle: "\(stats.pullRequests?.totalCount ?? 0) opened", imageName: "pull_request_icon", tint: .mint),
                .init(title: "Discussions", subtitle: "\(stats.repositoryDiscussions?.totalCount ?? 0) started", imageName: "discussion_icon", tint: .blue),
                .init(title: "Starred", subtitle: "\(stats.starredRepositories?.totalCount ?? 0) repos", imageName: "starred_icon", tint: .indigo),
            ]
        } catch {
            print("GraphQL Quick Actions error: \(error)")
            return fallback
        }
    }

    func fetchMyIssues(for username: String, token: String?) async -> [MyIssue] {
        let user = clean(username)
        guard !user.isEmpty else { return [] }

        let query = """
        { user(login: "\(user)") { issues(first: 50, filterBy: { createdBy: "\(user)" }, orderBy: {field: CREATED_AT, direction: DESC}) {
        nodes { number title state bodyText url repository { nameWithOwner } createdAt updatedAt } } } }
        """

        do {
            let decoded: GraphQLMyIssuesResponse = try await executeGraphQL(query: query, token: token)
            guard let nodes = decoded.data?.user?.issues?.nodes else { return [] }
            return nodes.map { node in
                MyIssue(id: node.number, number: node.number, title: node.title, state: node.state.lowercased(),
                        body: node.bodyText, htmlURL: node.url, repositoryName: node.repository.nameWithOwner,
                        createdAt: node.createdAt, updatedAt: node.updatedAt)
            }
        } catch {
            print("GraphQL fetchMyIssues error: \(error)")
            return []
        }
    }

    func fetchMyPullRequests(for username: String, token: String?) async -> [MyPullRequest] {
        let user = clean(username)
        guard !user.isEmpty else { return [] }

        let query = """
        { user(login: "\(user)") { pullRequests(first: 50, states: [OPEN, CLOSED, MERGED], orderBy: { field: CREATED_AT, direction: DESC }) {
        nodes { number title state bodyText url repository { nameWithOwner } createdAt updatedAt } } } }
        """

        do {
            let decoded: GraphQLMyPullRequestsResponse = try await executeGraphQL(query: query, token: token)
            guard let nodes = decoded.data?.user?.pullRequests?.nodes else { return [] }
            return nodes.map { node in
                MyPullRequest(id: node.number, number: node.number, title: node.title, state: node.state.lowercased(),
                              body: node.bodyText, htmlURL: node.url, repositoryName: node.repository.nameWithOwner,
                              createdAt: node.createdAt, updatedAt: node.updatedAt)
            }
        } catch {
            print("GraphQL fetchMyPullRequests error: \(error)")
            return []
        }
    }

    func fetchMyDiscussions(for username: String, token: String?) async -> [MyDiscussion] {
        let user = clean(username)
        guard !user.isEmpty else { return [] }

        let query = """
        { user(login: "\(user)") { repositoryDiscussions(first: 50) { nodes {
        id title body url repository { nameWithOwner } createdAt updatedAt } } } }
        """

        do {
            let decoded: GraphQLMyDiscussionsResponse = try await executeGraphQL(query: query, token: token)
            guard let nodes = decoded.data?.user?.repositoryDiscussions?.nodes else { return [] }
            return nodes.map { node in
                MyDiscussion(id: node.id, title: node.title, body: node.body, url: node.url,
                             repositoryName: node.repository.nameWithOwner, createdAt: node.createdAt,
                             updatedAt: node.updatedAt)
            }
        } catch {
            print("GraphQL fetchMyDiscussions error: \(error)")
            return []
        }
    }

    func fetchStarredRepositories(for username: String, token: String?) async -> [StarredRepository] {
        let user = clean(username)
        guard !user.isEmpty else { return [] }

        let query = """
        { user(login: "\(user)") { starredRepositories(first: 50) { nodes {
        id name nameWithOwner description url stargazerCount primaryLanguage { name } } } } }
        """

        do {
            let decoded: GraphQLStarredRepositoriesResponse = try await executeGraphQL(query: query, token: token)
            guard let nodes = decoded.data?.user?.starredRepositories?.nodes else { return [] }
            return nodes.map { node in
                StarredRepository(id: node.id, name: node.name, fullName: node.nameWithOwner,
                                  description: node.description, url: node.url, stars: node.stargazerCount,
                                  language: node.primaryLanguage?.name)
            }
        } catch {
            print("GraphQL fetchStarredRepositories error: \(error)")
            return []
        }
    }
}
