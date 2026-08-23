//
//  ContentViewModel.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import SwiftUI
import Combine

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var quickActions: [QuickAction] = [
        .init(title: "Issues", subtitle: "0 opened", imageName: "issue_icon", tint: .cyan),
        .init(title: "Pull Requests", subtitle: "0 opened", imageName: "pull_request_icon", tint: .mint),
        .init(title: "Discussions", subtitle: "0 started", imageName: "discussion_icon", tint: .blue),
        .init(title: "Starred", subtitle: "0 repos", imageName: "starred_icon", tint: .indigo)
    ]
    
    @Published var pinnedRepos: [PinnedRepo] = []
    @Published var activities: [ActivityItem] = []
    @Published var myWork: [WorkItem] = []
    @Published var avatarURL: String? = nil
    @Published var profileReadme: String? = nil
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
        async let fetchedDiscussions = service.fetchMyDiscussions(
            for: username,
            token: token
        )
        async let fetchedStarredRepositories = service.fetchStarredRepositories(
            for: username,
            token: token
        )
        
        let avatar = await fetchedAvatar
        let repos = await fetchedRepos
        let events = await fetchedEvents
        let work = await fetchedWork
        let actions = await fetchedActions
        let stats = await fetchedStats
        let issues = await fetchedIssues
        let pullRequests = await fetchedPullRequests
        let discussions = await fetchedDiscussions
        let starredRepositories = await fetchedStarredRepositories
        
        self.avatarURL = avatar
        self.pinnedRepos = repos
        self.activities = events
        self.myWork = work
        self.quickActions = actions
        self.myIssues = issues
        self.myPullRequests = pullRequests
        self.myDiscussions = discussions
        self.starredRepositories = starredRepositories
        
        let openIssuesCount = issues.filter { $0.state == "open" }.count
        if let index = self.quickActions.firstIndex(where: { $0.title == "Issues" }) {
            self.quickActions[index].subtitle = "\(openIssuesCount) opened"
        }
        
        let openPullRequestsCount = pullRequests.filter { $0.state == "open" }.count
        if let index = self.quickActions.firstIndex(where: { $0.title == "Pull Requests" }) {
            self.quickActions[index].subtitle = "\(openPullRequestsCount) opened"
        }
        
        if let stats = stats {
            self.followers = stats.followers
            self.following = stats.following
        }
        
        let discussionCount = discussions.count

        if let index = self.quickActions.firstIndex(
            where: { $0.title == "Discussions" }
        ) {
            self.quickActions[index].subtitle =
                "\(discussionCount) started"
        }

        let starredRepositoryCount = starredRepositories.count

        if let index = self.quickActions.firstIndex(
            where: { $0.title == "Starred" }
        ) {
            self.quickActions[index].subtitle =
                "\(starredRepositoryCount) repos"
        }
    }
    
    func fetchReadme(for username: String, token: String? = nil) async {
        guard profileReadme == nil else { return }
        self.profileReadme = await service.fetchUserReadme(for: username, token: token)
    }
}
