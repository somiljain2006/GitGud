//
//  ContentView.swift
//  GitGud
//
//  Created by somil jain on 13/07/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @StateObject private var inboxViewModel = InboxViewModel()
    @EnvironmentObject private var session: SessionStore
    @State private var isShowingAllRepos = false
    @State private var visitedTabs: Set<DockTab> = [.home]
    @State private var exploreViewModel: ExploreViewModel?
    @State private var showingReadme = false
    @State private var showingAISearchPanel = false

    var body: some View {
        ZStack {
            background

            ZStack {
                ForEach(DockTab.allCases, id: \.self) { tab in
                    if visitedTabs.contains(tab) {
                        tabContent(for: tab)
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity
                            )
                            .opacity(
                                viewModel.selectedTab == tab ? 1 : 0
                            )
                            .allowsHitTesting(
                                viewModel.selectedTab == tab
                            )
                    }
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )

            VStack(spacing: 0) {
                Spacer()

                if showingAISearchPanel {
                    AISearchPanelPlaceholder {
                        showingAISearchPanel = false
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 10)
                    .transition(
                        .move(edge: .bottom)
                            .combined(with: .opacity)
                    )
                    .zIndex(10)
                }

                bottomDock
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .preferredColorScheme(.dark)
        .sheet(isPresented: $isShowingAllRepos) {
            AllRepositoriesView(
                username: session.githubUsername,
                pinnedRepos: viewModel.pinnedRepos
            )
        }
        .sheet(isPresented: $showingReadme) {
            if let readme = viewModel.profileReadme {
                ProfileReadmeView(
                    htmlContent: readme,
                    username: session.githubUsername,
                    followers: viewModel.followers,
                    following: viewModel.following
                )
                .preferredColorScheme(.dark)
            } else {
                NavigationView {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.cyan)

                        Text("Loading README...")
                            .foregroundStyle(.secondary)
                    }
                    .task {
                        let username = session.githubUsername
                        let token = session.savedAccessKey

                        await viewModel.fetchReadme(
                            for: username,
                            token: token
                        )
                    }
                    .toolbar {
                        ToolbarItem(
                            placement: .navigationBarTrailing
                        ) {
                            Button("Close") {
                                showingReadme = false
                            }
                        }
                    }
                }
                .preferredColorScheme(.dark)
            }
        }
        .sheet(isPresented: $viewModel.showingMyIssues) {
            MyIssuesView(
                issues: viewModel.myIssues
            )
        }
        .sheet(isPresented: $viewModel.showingMyPullRequests) {
            MyPullRequestsView(
                pullRequests: viewModel.myPullRequests
            )
        }
        .sheet(isPresented: $viewModel.showingMyDiscussions) {
            MyDiscussionsView(
                discussions: viewModel.myDiscussions
            )
        }
        .sheet(isPresented: $viewModel.showingStarredRepositories) {
            StarredRepositoriesView(
                repositories: viewModel.starredRepositories
            )
        }
        .task {
            let username = session.githubUsername
            let token = session.savedAccessKey

            await viewModel.refreshData(
                for: username,
                token: token
            )

            if exploreViewModel == nil {
                exploreViewModel = ExploreViewModel(
                    session: session
                )
            }
        }
    }

    @ViewBuilder
    private func tabContent(for tab: DockTab) -> some View {
        switch tab {
        case .home:
            homeContent
        case .inbox:
            InboxView(viewModel: inboxViewModel)
        case .aiSearch:
            EmptyView()
        case .explore:
            if let exploreViewModel {
                ExploreView(viewModel: exploreViewModel)
            } else {
                ProgressView()
                    .tint(.cyan)
            }
        case .repos:
            RepositoriesView()
        }
    }

    private var homeContent: some View {
        ScrollView(
            [.vertical],
            showsIndicators: false
        ) {
            VStack(
                alignment: .leading,
                spacing: 24
            ) {
                HeaderSection(
                    avatarURL: viewModel.avatarURL
                )
                .onTapGesture {
                    showingReadme = true
                }

                QuickActionsSection(
                    actions: viewModel.quickActions
                ) { action in
                    switch action.title {
                    case "Issues":
                        viewModel.showingMyIssues = true

                    case "Pull Requests":
                        viewModel.showingMyPullRequests = true

                    case "Discussions":
                        viewModel.showingMyDiscussions = true

                    case "Starred":
                        viewModel.showingStarredRepositories = true

                    default:
                        break
                    }
                }

                PinnedRepositoriesSection(
                    repos: viewModel.pinnedRepos
                ) {
                    isShowingAllRepos = true
                }

                RecentActivitySection(
                    activities: viewModel.activities
                )

                MyWorkSection(
                    items: viewModel.myWork
                )
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 140)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .refreshable {
            let username = session.githubUsername
            let token = session.savedAccessKey

            await viewModel.refreshData(
                for: username,
                token: token
            )
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.09, blue: 0.12),
                Color(red: 0.03, green: 0.08, blue: 0.16),
                Color(red: 0.04, green: 0.05, blue: 0.12),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            ZStack {
                RadialGradient(
                    colors: [Color.cyan.opacity(0.14), .clear],
                    center: .topLeading,
                    startRadius: 20,
                    endRadius: 320
                )

                RadialGradient(
                    colors: [Color.blue.opacity(0.14), .clear],
                    center: .bottomTrailing,
                    startRadius: 20,
                    endRadius: 340
                )
            }
        )
        .ignoresSafeArea()
    }

    private var bottomDock: some View {
        HStack(spacing: 0) {
            ForEach(DockTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        if tab == .aiSearch {
                            showingAISearchPanel.toggle()
                        } else {
                            showingAISearchPanel = false
                            visitedTabs.insert(tab)
                            viewModel.selectedTab = tab
                        }
                    }
                } label: {
                    DockItem(
                        title: tab.title,
                        systemImage: tab.icon,
                        isSelected: viewModel.selectedTab == tab
                            || (tab == .aiSearch && showingAISearchPanel),
                        showDot: tab == .inbox
                            ? inboxViewModel.hasUnreadNotifications
                            : tab.hasNotification,
                        isAI: tab == .aiSearch
                    )
                }
                .buttonStyle(.plain)
                .opacity(
                    tab == .aiSearch && showingAISearchPanel
                        ? 0
                        : 1
                )
                .allowsHitTesting(
                    !(tab == .aiSearch && showingAISearchPanel)
                )
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.4), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 10)
        .shadow(color: Color.cyan.opacity(0.12), radius: 24, x: 0, y: 8)
        .padding(.horizontal, 18)
        .padding(.bottom, -20)
    }
}

#Preview {
    ContentView()
        .environmentObject(SessionStore())
}
