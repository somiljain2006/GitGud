//
//  ContentView.swift
//  GitGud
//
//  Created by somil jain on 13/07/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @EnvironmentObject private var session: SessionStore
    @State private var isShowingAllRepos = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            background
            
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
                        showDot: tab.hasNotification
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(.ultraThinMaterial.opacity(0.95))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.cyan.opacity(0.16), radius: 24, x: 0, y: 8)
        .padding(.horizontal, 18)
        .padding(.bottom, -20)
    }
}

#Preview {
    ContentView()
        .environmentObject(SessionStore())
}
