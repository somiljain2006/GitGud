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
        .init(title: "Issues", subtitle: "5 opened", imageName: "issue_icon", tint: .cyan),
        .init(title: "Pull Requests", subtitle: "3 opened", imageName: "pull_request_icon", tint: .mint),
        .init(title: "Discussions", subtitle: "3 started", imageName: "discussion_icon", tint: .blue),
        .init(title: "Starred", subtitle: "2 repos", imageName: "starred_icon", tint: .indigo)
    ]
    
    @Published var pinnedRepos: [PinnedRepo] = []
    @Published var activities: [ActivityItem] = []
    @Published var myWork: [WorkItem] = []
    @Published var avatarURL: String? = nil
    
    @Published var selectedTab: DockTab = .home
    
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
        
        let (avatar, repos, events, work, actions) = await (fetchedAvatar, fetchedRepos, fetchedEvents, fetchedWork, fetchedActions)
        
        self.avatarURL = avatar
        self.pinnedRepos = repos
        self.activities = events
        self.myWork = work
        self.quickActions = actions
    }
}
