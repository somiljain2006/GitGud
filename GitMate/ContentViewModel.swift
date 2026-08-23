//
//  ContentViewModel.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import Combine
import SwiftUI

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var quickActions: [QuickAction] = [
        .init(title: "Issues", subtitle: "0 opened", imageName: "issue_icon", tint: .cyan),
        .init(title: "Pull Requests", subtitle: "0 opened", imageName: "pull_request_icon", tint: .mint),
        .init(title: "Discussions", subtitle: "0 started", imageName: "discussion_icon", tint: .blue),
        .init(title: "Starred", subtitle: "0 repos", imageName: "starred_icon", tint: .indigo),
    ]

    @Published var pinnedRepos: [PinnedRepo] = []
    @Published var activities: [ActivityItem] = []
    @Published var myWork: [WorkItem] = []
    @Published var avatarURL: String?
    @Published var profileReadme: String?
    @Published var selectedTab: DockTab = .home
    @Published var followers: Int = 0
    @Published var following: Int = 0
    @Published var myIssues: [MyIssue] = []
    @Published var showingMyIssues = false
    @Published var myPullRequests: [MyPullRequest] = []
    @Published var showingMyPullRequests = false
    @Published var myDiscussions: [MyDiscussion] = []
    @Published var showingMyDiscussions = false
    @Published var starredRepositories: [StarredRepository] = []
    @Published var showingStarredRepositories = false

    private let service: GitHubService

    init(service: GitHubService? = nil) {
        self.service = service ?? GitHubService()
    }

    func refreshData(for username: String, token: String? = nil) async {
        async let fetchedAvatar = service.fetchUserAvatar(for: username, token: token)
        async let fetchedRepos = service.fetchRepositories(for: username, token: token)
        async let fetchedEvents = service.fetchRecentActivity(for: username)
        async let fetchedWork = service.fetchMyWork(for: username, token: token)
        async let fetchedActions = service.fetchQuickActions(for: username, token: token)
        async let fetchedStats = service.fetchUserStats(for: username, token: token)
        async let fetchedIssues = service.fetchMyIssues(for: username, token: token)
        async let fetchedPullRequests = service.fetchMyPullRequests(for: username, token: token)
        async let fetchedDiscussions = service.fetchMyDiscussions(for: username, token: token)
        async let fetchedStarredRepos = service.fetchStarredRepositories(for: username, token: token)

        avatarURL = await fetchedAvatar
        pinnedRepos = await fetchedRepos
        activities = await fetchedEvents
        myWork = await fetchedWork
        quickActions = await fetchedActions

        let issues = await fetchedIssues
        let pullRequests = await fetchedPullRequests
        let discussions = await fetchedDiscussions
        let starredRepos = await fetchedStarredRepos

        myIssues = issues
        myPullRequests = pullRequests
        myDiscussions = discussions
        starredRepositories = starredRepos

        if let stats = await fetchedStats {
            followers = stats.followers
            following = stats.following
        }

        updateQuickActionSubtitles(
            issues: issues,
            pullRequests: pullRequests,
            discussions: discussions,
            starredRepos: starredRepos
        )
    }

    private func updateQuickActionSubtitles(
        issues: [MyIssue],
        pullRequests: [MyPullRequest],
        discussions: [MyDiscussion],
        starredRepos: [StarredRepository]
    ) {
        let openIssuesCount = issues.filter { $0.state == "open" }.count
        if let index = quickActions.firstIndex(where: { $0.title == "Issues" }) {
            quickActions[index].subtitle = "\(openIssuesCount) opened"
        }

        let openPullRequestsCount = pullRequests.filter { $0.state == "open" }.count
        if let index = quickActions.firstIndex(where: { $0.title == "Pull Requests" }) {
            quickActions[index].subtitle = "\(openPullRequestsCount) opened"
        }

        if let index = quickActions.firstIndex(where: { $0.title == "Discussions" }) {
            quickActions[index].subtitle = "\(discussions.count) started"
        }

        if let index = quickActions.firstIndex(where: { $0.title == "Starred" }) {
            quickActions[index].subtitle = "\(starredRepos.count) repos"
        }
    }

    func fetchReadme(for username: String, token: String? = nil) async {
        guard profileReadme == nil else { return }
        profileReadme = await service.fetchUserReadme(for: username, token: token)
    }
}
