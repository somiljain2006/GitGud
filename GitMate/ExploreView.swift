//  ExploreView.swift
//  GitMate
//
//  Created by somil jain on 04/08/26.
//

import SwiftUI
import Combine

struct SearchRepositoriesResponse: Codable {
    let items: [SearchRepoItem]
}

struct SearchRepoItem: Codable {
    let name: String
    let owner: RepoOwner
    let description: String?
    let language: String?
    let stargazersCount: Int
    let forksCount: Int

    enum CodingKeys: String, CodingKey {
        case name, owner, description, language
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
    }
}

struct RepoOwner: Codable {
    let login: String
}

struct UserEvent: Codable {
    let id: String
    let type: String
    let actor: EventActor
    let repo: EventRepo
    let createdAt: String
    let payload: EventPayload?

    enum CodingKeys: String, CodingKey {
        case id, type, actor, repo, payload
        case createdAt = "created_at"
    }
}

struct Commit: Codable {
    let message: String
}

struct Issue: Codable {
    let title: String
}

struct PullRequest: Codable {
    let title: String
}

struct EventPayload: Codable {
    let action: String?
    let commits: [Commit]?
    let issue: Issue?
    let pullRequest: PullRequest?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case action, commits, issue, description
        case pullRequest = "pull_request"
    }
}

struct EventActor: Codable {
    let login: String
    let avatarUrl: String

    enum CodingKeys: String, CodingKey {
        case login
        case avatarUrl = "avatar_url"
    }
}

struct EventRepo: Codable {
    let name: String
}

struct FollowedUser: Codable {
    let login: String
}

struct FeedOrganization: Codable {
    let login: String
}

struct FeedRepository: Codable {
    let fullName: String

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
    }
}

struct TrendingRepo: Identifiable {
    let id = UUID()
    let owner: String
    let name: String
    let description: String
    let language: String
    let languageColor: Color
    let stars: String
    let forks: String
    var isStarred: Bool
}

struct ExploreActivity: Identifiable {
    let id = UUID()
    let actorName: String
    let actorAvatar: String
    let actionText: String
    let targetRepo: String
    let timeAgo: String
    let actionDetail: String?
}

@MainActor
final class ExploreViewModel: ObservableObject {
    @Published var trendingRepos: [TrendingRepo] = []
    @Published var exploreActivities: [ExploreActivity] = []
    @Published var suggestedRepo: TrendingRepo?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let session: SessionStore

    init(session: SessionStore) {
        self.session = session
    }

    func fetchData() async {
        isLoading = true
        errorMessage = nil
        
        async let trending = fetchTrendingRepos()
        async let activities = fetchExploreActivities()
        async let suggested = fetchSuggestedRepo()
        
        do {
            let (fetchedTrending, fetchedActivities, fetchedSuggested) = try await (trending, activities, suggested)
            self.trendingRepos = fetchedTrending
            self.exploreActivities = fetchedActivities
            self.suggestedRepo = fetchedSuggested
        } catch {
            self.errorMessage = error.localizedDescription
            print("Explore Fetch Error: \(error)")
        }
        
        isLoading = false
    }
    
    func toggleStar(owner: String, repo: String, isStarred: Bool) async -> Bool {
        let path = "/user/starred/\(owner)/\(repo)"
        let method = isStarred ? "PUT" : "DELETE"
        
        do {
            _ = try await performAuthenticatedRequest(path: path, method: method)
            return true
        } catch {
            print("Failed to toggle star for \(owner)/\(repo): \(error)")
            return false
        }
    }
    
    private func fetchSuggestedRepo() async throws -> TrendingRepo? {
        let techStackKeywords = ["swiftui", "ios", "swift", "combine", "coreml", "arkit"]
        let randomKeyword = techStackKeywords.randomElement() ?? "swift"
        
        var components = URLComponents(string: "https://api.github.com/search/repositories")!
        components.queryItems = [
            URLQueryItem(name: "q", value: "\(randomKeyword) language:swift"),
            URLQueryItem(name: "sort", value: "stars"),
            URLQueryItem(name: "order", value: "desc"),
            URLQueryItem(name: "per_page", value: "30")
        ]
        
        guard let urlString = components.url?.absoluteString else {
            throw URLError(.badURL)
        }
        
        let data = try await performAuthenticatedRequest(url: urlString)
        let response = try JSONDecoder().decode(SearchRepositoriesResponse.self, from: data)
        
        guard let randomItem = response.items.randomElement() else { return nil }
        
        return TrendingRepo(
            owner: randomItem.owner.login,
            name: randomItem.name,
            description: randomItem.description ?? "No description provided.",
            language: randomItem.language ?? "Unknown",
            languageColor: colorForLanguage(randomItem.language),
            stars: formatCount(randomItem.stargazersCount),
            forks: formatCount(randomItem.forksCount),
            isStarred: false
        )
    }

    private func fetchTrendingRepos() async throws -> [TrendingRepo] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let dateString = formatter.string(from: sevenDaysAgo)
        
        var components = URLComponents(string: "https://api.github.com/search/repositories")!
        components.queryItems = [
            URLQueryItem(name: "q", value: "pushed:>\(dateString) stars:>100"),
            URLQueryItem(name: "sort", value: "stars"),
            URLQueryItem(name: "order", value: "desc"),
            URLQueryItem(name: "per_page", value: "10")
        ]
        
        guard let urlString = components.url?.absoluteString else {
            throw URLError(.badURL)
        }
        
        let data = try await performAuthenticatedRequest(url: urlString)
        let response = try JSONDecoder().decode(SearchRepositoriesResponse.self, from: data)
        
        return response.items.map { item in
            TrendingRepo(
                owner: item.owner.login,
                name: item.name,
                description: item.description ?? "No description provided.",
                language: item.language ?? "Unknown",
                languageColor: colorForLanguage(item.language),
                stars: formatCount(item.stargazersCount),
                forks: formatCount(item.forksCount),
                isStarred: false
            )
        }
    }

    private func fetchExploreActivities() async throws -> [ExploreActivity] {
        let username = session.githubUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !username.isEmpty else { return [] }
        
        var events = await fetchEvents(path: "/users/\(username)/received_events", perPage: 20)
        
        if events.isEmpty {
            events = await fetchContextualFallbackEvents(for: username)
        }
        
        return events
            .deduplicatedByID()
            .sortedByCreationDateDescending()
            .prefix(20)
            .map { event in
                ExploreActivity(
                    actorName: event.actor.login,
                    actorAvatar: event.actor.avatarUrl,
                    actionText: actionText(for: event.type),
                    targetRepo: event.repo.name,
                    timeAgo: formatTimeAgo(from: event.createdAt),
                    actionDetail: extractActionDetail(from: event)
                )
            }
    }

    private func fetchContextualFallbackEvents(for username: String) async -> [UserEvent] {
        async let followedUsers = fetchFollowedUsers()
        async let watchedRepositories = fetchWatchedRepositories()
        async let organizations = fetchAuthenticatedOrganizations()
        async let starredRepositories = fetchStarredRepositories(for: username)
        async let ownEvents = fetchEvents(path: "/users/\(username)/events", perPage: 5)
        
        let context = await (
            followedUsers.prefix(10),
            watchedRepositories.prefix(5),
            organizations.prefix(5),
            starredRepositories.prefix(5),
            ownEvents
        )
        
        return await withTaskGroup(of: [UserEvent].self) { group in
            for user in context.0 {
                group.addTask {
                    await self.fetchEvents(path: "/users/\(user.login)/events/public", perPage: 3)
                }
            }
            
            for repository in context.1 {
                group.addTask {
                    await self.fetchEvents(path: "/repos/\(repository.fullName)/events", perPage: 3)
                }
            }
            
            for organization in context.2 {
                group.addTask {
                    await self.fetchEvents(path: "/users/\(username)/events/orgs/\(organization.login)", perPage: 3)
                }
            }
            
            for repository in context.3 {
                group.addTask {
                    await self.fetchEvents(path: "/repos/\(repository.fullName)/events", perPage: 3)
                }
            }
            
            var events = context.4
            for await sourceEvents in group {
                events.append(contentsOf: sourceEvents)
            }
            
            return events
        }
    }
    
    private func fetchFollowedUsers() async -> [FollowedUser] {
        await fetchDecoded(path: "/user/following", perPage: 10) ?? []
    }
    
    private func fetchWatchedRepositories() async -> [FeedRepository] {
        await fetchDecoded(path: "/user/subscriptions", perPage: 5) ?? []
    }
    
    private func fetchAuthenticatedOrganizations() async -> [FeedOrganization] {
        await fetchDecoded(path: "/user/orgs", perPage: 5) ?? []
    }
    
    private func fetchStarredRepositories(for username: String) async -> [FeedRepository] {
        await fetchDecoded(path: "/users/\(username)/starred", perPage: 5) ?? []
    }
    
    private func fetchEvents(path: String, perPage: Int) async -> [UserEvent] {
        await fetchDecoded(path: path, perPage: perPage) ?? []
    }
    
    private func fetchDecoded<T: Decodable>(path: String, perPage: Int) async -> T? {
        do {
            let data = try await performAuthenticatedRequest(path: path, queryItems: [
                URLQueryItem(name: "per_page", value: "\(perPage)")
            ])
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Explore feed request failed for \(path): \(error)")
            return nil
        }
    }

    private func performAuthenticatedRequest(path: String, method: String = "GET", queryItems: [URLQueryItem] = []) async throws -> Data {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.github.com"
        components.path = path
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let endpoint = components.url else { throw URLError(.badURL) }
        return try await performAuthenticatedRequest(url: endpoint, method: method)
    }
    
    private func performAuthenticatedRequest(url urlString: String, method: String = "GET") async throws -> Data {
        guard let endpoint = URL(string: urlString) else { throw URLError(.badURL) }
        return try await performAuthenticatedRequest(url: endpoint, method: method)
    }
    
    private func performAuthenticatedRequest(url: URL, method: String = "GET") async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.addValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.addValue("GitGudApp", forHTTPHeaderField: "User-Agent")
        
        if let token = session.savedAccessKey {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return data
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        }
        return "\(count)"
    }

    private func formatTimeAgo(from isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return "recently" }
        
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .abbreviated
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    private func actionText(for eventType: String) -> String {
        switch eventType {
        case "WatchEvent": return "starred"
        case "PushEvent": return "pushed to"
        case "CreateEvent": return "created a repository"
        case "ForkEvent": return "forked"
        case "IssuesEvent": return "opened an issue in"
        case "PullRequestEvent": return "opened a pull request in"
        default: return "interacted with"
        }
    }

    private func colorForLanguage(_ language: String?) -> Color {
        switch language?.lowercased() {
        case "swift": return .orange
        case "javascript", "typescript": return .yellow
        case "python": return .blue
        case "ruby": return .red
        case "java": return .brown
        case "go": return .cyan
        case "html", "css": return .purple
        default: return .gray
        }
    }
    
    private func extractActionDetail(from event: UserEvent) -> String? {
        guard let payload = event.payload else { return nil }
        
        switch event.type {
        case "PushEvent":
            return payload.commits?.first?.message.components(separatedBy: "\n").first
        case "IssuesEvent":
            return payload.issue?.title
        case "PullRequestEvent":
            return payload.pullRequest?.title
        case "CreateEvent":
            return payload.description
        default:
            return nil
        }
    }
}

private extension Array where Element == UserEvent {
    func deduplicatedByID() -> [UserEvent] {
        var seenIDs = Set<String>()
        return filter { event in
            seenIDs.insert(event.id).inserted
        }
    }
    
    func sortedByCreationDateDescending() -> [UserEvent] {
        sorted { $0.createdAt > $1.createdAt }
    }
}

struct ExploreView: View {
    @StateObject var viewModel: ExploreViewModel
    @State private var isSearchPresented = false
    
    private let activityCardHeight: CGFloat = 72
    private let activitySpacing: CGFloat = 14
    private let visibleCardCount: CGFloat = 3

    private var exploreFeedBoxHeight: CGFloat {
        (activityCardHeight * visibleCardCount) + (activitySpacing * (visibleCardCount - 1)) + 32
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 36) {
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Trending This Week")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Button {
                            isSearchPresented.toggle()
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(10)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Circle())
                        }
                    }
                    
                    if viewModel.isLoading && viewModel.trendingRepos.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.trendingRepos.indices, id: \.self) { index in
                                    TrendingCardView(repo: $viewModel.trendingRepos[index]) { isStarred in
                                        await viewModel.toggleStar(
                                            owner: viewModel.trendingRepos[index].owner,
                                            repo: viewModel.trendingRepos[index].name,
                                            isStarred: isStarred
                                        )
                                    }
                                    .frame(width: 330)
                                }
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Explore")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    if viewModel.isLoading && viewModel.exploreActivities.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            ScrollView(.vertical, showsIndicators: false) {
                                LazyVStack(spacing: 14) {
                                    ForEach(viewModel.exploreActivities) { activity in
                                        ExploreActivityCard(activity: activity)
                                    }
                                }
                                .padding(16)
                            }
                        }
                        .frame(height: exploreFeedBoxHeight)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                }
                
                if viewModel.suggestedRepo != nil || viewModel.isLoading {
                    VStack(alignment: .leading, spacing: 32) {
                        Text("Suggested Repository")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            
                        if viewModel.isLoading && viewModel.suggestedRepo == nil {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        } else if viewModel.suggestedRepo != nil {
                            
                            TrendingCardView(repo: Binding(
                                get: { viewModel.suggestedRepo! },
                                set: { viewModel.suggestedRepo = $0 }
                            )) { isStarred in
                                await viewModel.toggleStar(
                                    owner: viewModel.suggestedRepo!.owner,
                                    repo: viewModel.suggestedRepo!.name,
                                    isStarred: isStarred
                                )
                            }
                            .frame(height: 200)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 140)
        }
        .refreshable {
            await viewModel.fetchData()
        }
        .task {
            if viewModel.trendingRepos.isEmpty && viewModel.exploreActivities.isEmpty {
                await viewModel.fetchData()
            }
        }
    }
}

struct TrendingCardView: View {
    @Binding var repo: TrendingRepo
    
    var onToggleStar: ((Bool) async -> Bool)?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            
            HStack(spacing: 10) {
                Image(systemName: "square.3.layers.3d.down.right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(Color.cyan)
                
                Text("\(repo.owner) / \(repo.name)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            
            Text(repo.description)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(2)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 0)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(repo.languageColor)
                            .frame(width: 10, height: 10)
                        Text(repo.language)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star")
                            .font(.system(size: 12))
                        Text(repo.stars)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                    }
                    .foregroundStyle(.white.opacity(0.85))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "tuningfork")
                            .font(.system(size: 12))
                        Text(repo.forks)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                    }
                    .foregroundStyle(.white.opacity(0.85))
                }
                
                Button {
                    let previousState = repo.isStarred
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        repo.isStarred.toggle()
                    }
                    
                    Task {
                        if let onToggleStar = onToggleStar {
                            let success = await onToggleStar(repo.isStarred)
                            
                            if !success {
                                await MainActor.run {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        repo.isStarred = previousState
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: repo.isStarred ? "star.fill" : "star")
                            .font(.system(size: 12, weight: .bold))
                        Text(repo.isStarred ? "STARRED" : "STAR REPO")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(Color.cyan)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .stroke(Color.cyan.opacity(0.6), lineWidth: 1)
                    )
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.cyan.opacity(0.25), lineWidth: 1)
            )
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.cyan.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

struct ExploreActivityCard: View {
    let activity: ExploreActivity

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            
            AsyncImage(url: URL(string: activity.actorAvatar)) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.cyan.opacity(0.8))
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text("\(Text(activity.actorName).fontWeight(.bold)) \(activity.actionText) \(Text(activity.targetRepo).fontWeight(.semibold).foregroundColor(.cyan))")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Text(activity.timeAgo)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(1)
                }
                
                if let description = activity.actionDetail {
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(2)
                }
            }
        }
        .frame(minHeight: 72)
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview {
    ExploreView(viewModel: ExploreViewModel(session: SessionStore()))
}
