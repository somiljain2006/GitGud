//
//  ContentView.swift
//  GitGud
//
//  Created by somil jain on 13/07/26.
//

import SwiftUI

struct ContentView: View {
    private let quickActions: [QuickAction] = [
        .init(title: "Issues", systemImage: "exclamationmark.circle.fill", tint: .cyan),
        .init(title: "Pull Requests", systemImage: "arrow.triangle.branch", tint: .mint),
        .init(title: "Discussions", systemImage: "bubble.left.and.bubble.right.fill", tint: .blue),
        .init(title: "Starred", systemImage: "star.fill", tint: .indigo)
    ]
    
    private let pinnedRepos: [PinnedRepo] = [
        .init(
            name: "stitch-core",
            description: "High-performance reactive UI framework for the modern web, written in Rust and TypeScript.",
            language: "Rust",
            stars: "1.2k",
            isPublic: true,
            color: .cyan
        ),
        .init(
            name: "aurora-ui",
            description: "Design system components and tokens for internal dashboard applications.",
            language: "TypeScript",
            stars: "48",
            isPublic: false,
            color: .mint
        )
    ]
    
    private let activities: [ActivityItem] = [
        .init(
            title: "PR #42 opened",
            subtitle: "in stitch-core",
            timestamp: "2 hours ago",
            systemImage: "arrow.triangle.branch",
            tint: .mint
        ),
        .init(
            title: "Review submitted",
            subtitle: "for aurora-ui",
            timestamp: "5 hours ago",
            systemImage: "checkmark",
            tint: .cyan
        ),
        .init(
            title: "Forked",
            subtitle: "nexus-lab",
            timestamp: "Yesterday",
            systemImage: "arrow.triangle.merge",
            tint: .blue
        )
    ]

    private let myWork: [WorkItem] = [
        .init(
            repository: "jenkinsci / JiraTestResultReporter-plugin #311",
            title: "Make JiraTestResultReporter global configuration exportable by JCasC",
            description: "You received a review",
            time: "8h",
            comments: 2,
            type: .review
        ),
        .init(
            repository: "open-telemetry / opentelemetry-java-instrumentation #19048",
            title: "Implement configurable metric bridge metric suppression",
            description: "opentelemetry-pr-dashboard commented",
            time: "10h",
            comments: 35,
            type: .pullRequest
        ),
        .init(
            repository: "crate / crate #19823",
            title: "Collect table statistics for foreign tables",
            description: "crate-jenkins commented",
            time: "15h",
            comments: 1,
            type: .issue
        ),
        .init(
            repository: "swiftlang / swift-book #473",
            title: "Fix function type grammar for labeled parameters",
            description: "You commented",
            time: "1d",
            comments: 3,
            type: .comment
        )
    ]
    
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
            
            Button(action: {}) {
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
                ForEach(quickActions) { action in
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
                
                Button("VIEW ALL") {}
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.cyan)
            }
            
            VStack(spacing: 12) {
                ForEach(pinnedRepos) { repo in
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
                // FIX: Let the content dictate the size, and apply GlassCard as background.
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 2)
                        .padding(.leading, 31)
                        .padding(.vertical, 22)
                    
                    VStack(spacing: 18) {
                        ForEach(activities) { activity in
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
                
                ForEach(myWork.indices, id: \.self) { index in
                    
                    WorkCard(item: myWork[index])
                    
                    if index != myWork.count - 1 {
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
            DockItem(title: "Home", systemImage: "house.fill", isSelected: true, showDot: false)
            DockItem(title: "Inbox", systemImage: "tray.fill", isSelected: false, showDot: false)
            DockItem(title: "AI Search", systemImage: "brain.head.profile", isSelected: false, showDot: true)
            DockItem(title: "Explore", systemImage: "safari", isSelected: false, showDot: false)
            DockItem(title: "Repos", systemImage: "shippingbox.fill", isSelected: false, showDot: false)
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
        Button(action: {}) {
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
                        Image(systemName: action.systemImage)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(action.tint)
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
        // FIX: Put content in layout flow and set GlassCard as the background
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

private struct QuickAction: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let tint: Color
}

private struct PinnedRepo: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let language: String
    let stars: String
    let isPublic: Bool
    let color: Color
}

private struct ActivityItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let timestamp: String
    let systemImage: String
    let tint: Color
}

private struct WorkItem: Identifiable {
    let id = UUID()
    let repository: String
    let title: String
    let description: String
    let time: String
    let comments: Int
    let type: NotificationType
}

private enum NotificationType {
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

#Preview {
    ContentView()
}
