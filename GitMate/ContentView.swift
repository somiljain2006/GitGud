//
//  ContentView.swift
//  GitGud
//
//  Created by somil jain on 13/07/26.
//

import SwiftUI
import Combine

@MainActor
class ContentViewModel: ObservableObject {
    @Published var quickActions: [QuickAction] = [
        .init(title: "Issues", imageName: "issue_icon", tint: .cyan),
        .init(title: "Pull Requests", imageName: "pull_request_icon", tint: .mint),
        .init(title: "Discussions", imageName: "discussion_icon", tint: .blue),
        .init(title: "Starred", imageName: "starred_icon", tint: .indigo)
    ]
    
    // Start with empty arrays; they will populate when the API loads
    @Published var pinnedRepos: [PinnedRepo] = []
    @Published var activities: [ActivityItem] = []
    
    // Keeping myWork static for now as GitHub's notifications API requires an authenticated token
    @Published var myWork: [WorkItem] = [
        .init(repository: "swiftlang / swift-book #473", title: "Fix function type grammar for labeled parameters", description: "You commented", time: "1d", comments: 3, type: .comment)
    ]
    
    @Published var selectedTab: DockTab = .home
    
    // MARK: - Networking
    
    func refreshData(for username: String) async {
        async let fetchedRepos = fetchRepositories(for: username)
        async let fetchedEvents = fetchRecentActivity(for: username)
        
        // Wait for both network calls to finish concurrently
        let (repos, events) = await (fetchedRepos, fetchedEvents)
        
        self.pinnedRepos = repos
        self.activities = events
    }
    
    private func fetchRepositories(for username: String) async -> [PinnedRepo] {
        // Sort by updated to simulate active/pinned repos
        guard let url = URL(string: "https://api.github.com/users/\(username)/repos?sort=updated&per_page=4") else { return [] }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedRepos = try JSONDecoder().decode([GitHubRepo].self, from: data)
            
            return decodedRepos.map { repo in
                PinnedRepo(
                    name: repo.name,
                    description: repo.description ?? "No description provided.",
                    language: repo.language ?? "Unknown",
                    stars: formatStars(repo.stargazers_count),
                    isPublic: !repo.private,
                    color: colorForLanguage(repo.language)
                )
            }
        } catch {
            print("Error fetching repos: \(error)")
            return []
        }
    }
    
    private func fetchRecentActivity(for username: String) async -> [ActivityItem] {
        guard let url = URL(string: "https://api.github.com/users/\(username)/events/public?per_page=4") else { return [] }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedEvents = try JSONDecoder().decode([GitHubEvent].self, from: data)
            
            return decodedEvents.map { event in
                let mappedType = mapEventType(event.type)
                return ActivityItem(
                    title: mappedType.title,
                    subtitle: event.repo.name,
                    timestamp: formatRelativeDate(from: event.created_at),
                    systemImage: mappedType.icon,
                    tint: mappedType.color
                )
            }
        } catch {
            print("Error fetching events: \(error)")
            return []
        }
    }
    
    // MARK: - Helpers
    
    private func formatStars(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        }
        return "\(count)"
    }
    
    private func colorForLanguage(_ language: String?) -> Color {
        switch language?.lowercased() {
        case "swift": return .orange
        case "rust": return .brown
        case "typescript", "javascript": return .yellow
        case "python": return .blue
        case "java": return .red
        default: return .cyan
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
    
    private func formatRelativeDate(from isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return "Recently" }
        
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .abbreviated
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            background
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    quickActionsSection
                    pinnedReposSection
                    recentActivitySection
                    myWorkSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 140)
            }
            
            bottomDock
        }
        .preferredColorScheme(.dark)
        .task {
            // Replace "apple" with your GitHub username
            await viewModel.refreshData(for: "apple")
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
                    colors: [
                        Color.cyan.opacity(0.14),
                        .clear
                    ],
                    center: .topLeading,
                    startRadius: 20,
                    endRadius: 320
                )
                
                RadialGradient(
                    colors: [
                        Color.blue.opacity(0.14),
                        .clear
                    ],
                    center: .bottomTrailing,
                    startRadius: 20,
                    endRadius: 340
                )
            }
        )
        .ignoresSafeArea()
    }
    
    private var header: some View {
        HStack {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.92))
                .background(
                    Circle()
                        .fill(.white.opacity(0.08))
                        .frame(width: 42, height: 42)
                )
            
            Spacer()
            
            Button(action: {
                // Dynamic Search Action
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.cyan)
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.08), in: Circle())
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.12), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick Actions")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(viewModel.quickActions) { action in
                    QuickActionCard(action: action)
                }
            }
        }
    }
    
    private var pinnedReposSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Pinned Repositories")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button("VIEW ALL") {
                    // Dynamic View All Action
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color.cyan)
            }
            
            VStack(spacing: 12) {
                ForEach(viewModel.pinnedRepos) { repo in
                    PinnedRepoCard(repo: repo)
                }
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Activity")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 2)
                        .padding(.leading, 31)
                        .padding(.vertical, 22)
                    
                    VStack(spacing: 18) {
                        ForEach(viewModel.activities) { activity in
                            ActivityRow(activity: activity)
                        }
                    }
                    .padding(16)
                }
                .background(GlassCard(cornerRadius: 18))
            }
        }
    }

    private var myWorkSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            
            Text("My Work")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            
            VStack(spacing: 0) {
                ForEach(viewModel.myWork.indices, id: \.self) { index in
                    WorkCard(item: viewModel.myWork[index])
                    
                    if index != viewModel.myWork.count - 1 {
                        Divider()
                            .overlay(Color.white.opacity(0.08))
                            .padding(.leading, 62)
                    }
                }
            }
            .padding(.vertical, 4)
            .background(GlassCard(cornerRadius: 20))
        }
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
        .padding(.bottom, 12)
    }
}

// MARK: - Components

private struct GlassCard: View {
    var cornerRadius: CGFloat = 20
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.06),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
    }
}

private struct QuickActionCard: View {
    let action: QuickAction
    
    var body: some View {
        Button(action: {
            // Action trigger dynamic to model
        }) {
            ZStack {
                GlassCard(cornerRadius: 20)
                
                LinearGradient(
                    colors: [
                        action.tint.opacity(0.18),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                
                VStack(alignment: .leading) {
                    HStack {
                        Spacer()
                        Image(action.imageName)
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(action.tint)
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                    }
                    
                    Spacer()
                    
                    Text(action.title)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                }
                .padding(14)
            }
            .frame(height: 132)
        }
        .buttonStyle(ScaledButtonStyle())
    }
}

private struct PinnedRepoCard: View {
    let repo: PinnedRepo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                HStack(spacing: 8) {
                    Image(systemName: "book")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.cyan)
                    
                    Text(repo.name)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                Text(repo.isPublic ? "Public" : "Private")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
            }
            
            Text(repo.description)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(2)
            
            HStack(spacing: 14) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(repo.color)
                        .frame(width: 10, height: 10)
                    Text(repo.language)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.72))
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "star")
                        .font(.system(size: 12, weight: .semibold))
                    Text(repo.stars)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                }
                .foregroundStyle(.white.opacity(0.72))
                
                Spacer()
                
                Text("Updated recently")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.42))
            }
        }
        .padding(16)
        .background(GlassCard(cornerRadius: 18))
    }
}

private struct ActivityRow: View {
    let activity: ActivityItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.14), lineWidth: 1)
                    )
                
                Image(systemName: activity.systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(activity.tint)
            }
            .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(activity.subtitle)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.70))
                
                Text(activity.timestamp)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.top, 2)
            }
            
            Spacer()
        }
        .padding(.leading, 2)
    }
}

private struct WorkCard: View {
    let item: WorkItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: item.type.icon)
                .font(.system(size: 28))
                .foregroundStyle(item.type.color)
                .frame(width: 34)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(item.repository)
                        .font(.system(size: 15))
                        .foregroundStyle(.gray)
                    
                    Spacer()
                    
                    Text(item.time)
                        .foregroundStyle(.gray)
                        .font(.system(size: 15))
                }
                
                Text(item.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(item.description)
                    .foregroundStyle(.gray)
                    .font(.system(size: 16))
            }
            
            VStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 42, height: 42)
                    .overlay {
                        Text("\(item.comments)")
                            .foregroundStyle(.gray)
                            .font(.system(size: 16, weight: .bold))
                    }
                
                Spacer()
            }
        }
        .padding(18)
    }
}

private struct DockItem: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let showDot: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.cyan : Color.white.opacity(0.65))
                
                if showDot {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 7, height: 7)
                        .shadow(color: .cyan.opacity(0.9), radius: 6)
                        .offset(x: 7, y: -6)
                }
            }
            
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? Color.cyan : Color.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
    }
}

private struct ScaledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Models

struct QuickAction: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    let tint: Color
}

struct PinnedRepo: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let language: String
    let stars: String
    let isPublic: Bool
    let color: Color
}

struct ActivityItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let timestamp: String
    let systemImage: String
    let tint: Color
}

struct WorkItem: Identifiable {
    let id = UUID()
    let repository: String
    let title: String
    let description: String
    let time: String
    let comments: Int
    let type: NotificationType
}

enum NotificationType {
    case pullRequest, issue, review, comment, ciFailed, ciPassed, discussion, release
    
    var icon: String {
        switch self {
        case .pullRequest: return "arrow.triangle.branch"
        case .issue: return "exclamationmark.circle"
        case .review: return "checkmark.circle"
        case .comment: return "message"
        case .ciFailed: return "xmark.octagon.fill"
        case .ciPassed: return "checkmark.seal.fill"
        case .discussion: return "bubble.left.and.bubble.right.fill"
        case .release: return "tag.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .pullRequest: return .green
        case .issue: return .orange
        case .review: return .cyan
        case .comment: return .blue
        case .ciFailed: return .red
        case .ciPassed: return .green
        case .discussion: return .purple
        case .release: return .pink
        }
    }
}

enum DockTab: String, CaseIterable {
    case home, inbox, aiSearch, explore, repos
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .inbox: return "Inbox"
        case .aiSearch: return "AI Search"
        case .explore: return "Explore"
        case .repos: return "Repos"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .inbox: return "tray.fill"
        case .aiSearch: return "brain.head.profile"
        case .explore: return "safari"
        case .repos: return "shippingbox.fill"
        }
    }
    
    var hasNotification: Bool {
        self == .aiSearch
    }
}

// MARK: - GitHub API Data Models

struct GitHubRepo: Codable {
    let name: String
    let description: String?
    let language: String?
    let stargazers_count: Int
    let `private`: Bool
}

struct GitHubEvent: Codable {
    let id: String
    let type: String
    let created_at: String
    let repo: EventRepo
    
    struct EventRepo: Codable {
        let name: String
    }
}

#Preview {
    ContentView()
}
