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
    
    var body: some View {
            ZStack(alignment: .bottom) {
                background
                
                Group {
                    switch viewModel.selectedTab {
                    case .home:
                        homeContent
                    case .inbox:
                        InboxView(viewModel: inboxViewModel)
                    case .aiSearch:
                        Text("AI Search").foregroundStyle(.white.opacity(0.5))
                    case .explore:
                        Text("Explore").foregroundStyle(.white.opacity(0.5))
                    case .repos:
                        Text("Repositories").foregroundStyle(.white.opacity(0.5))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                bottomDock
            }
            .preferredColorScheme(.dark)
            .sheet(isPresented: $isShowingAllRepos) {
                AllRepositoriesView(
                    username: session.githubUsername,
                    pinnedRepos: viewModel.pinnedRepos
                )
            }
            .task {
                let username = session.githubUsername
                let token = session.savedAccessKey
                await viewModel.refreshData(for: username, token: token)
            }
        }
        
        private var homeContent: some View {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    HeaderSection(avatarURL: viewModel.avatarURL)
                    QuickActionsSection(actions: viewModel.quickActions)
                    PinnedRepositoriesSection(repos: viewModel.pinnedRepos) {
                        isShowingAllRepos = true
                    }
                    RecentActivitySection(activities: viewModel.activities)
                    MyWorkSection(items: viewModel.myWork)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 140)
            }
        }
    
    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.09, blue: 0.12),
                Color(red: 0.03, green: 0.08, blue: 0.16),
                Color(red: 0.04, green: 0.05, blue: 0.12)
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
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedTab = tab
                    }
                } label: {
                    DockItem(
                        title: tab.title,
                        systemImage: tab.icon,
                        isSelected: viewModel.selectedTab == tab,
                        showDot: tab == .inbox ? inboxViewModel.hasUnreadNotifications : tab.hasNotification
                    )
                }
                .buttonStyle(.plain)
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
