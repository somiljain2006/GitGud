//
// RepositoriesView.swift
// GitMate
//
// Created by somil jain on 05/08/26.
//

import SwiftUI
import Combine

struct RepositoryItem: Identifiable {
    let id = UUID()
    let owner: String
    let name: String
    let description: String
    let language: String
    let languageColor: Color
    let languageLogo: String
    let stars: String
    let forks: String
    let updatedAgo: String
    let isPrivate: Bool
    let iconName: String
    var isStarred: Bool
}

struct GitHubRepoDetailed: Codable {
    let name: String
    let owner: RepoOwner
    let description: String?
    let language: String?
    let languagesUrl: String
    let stargazersCount: Int
    let forksCount: Int
    let `private`: Bool
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case name, owner, description, language, `private`
        case languagesUrl = "languages_url"
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
        case updatedAt = "updated_at"
    }
}

@MainActor
class RepositoriesViewModel: ObservableObject {
    @Published var selectedFilter: String = "All"
    @Published var filters: [String] = ["All"]
    @Published var allRepositories: [RepositoryItem] = []
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    var filteredRepositories: [RepositoryItem] {
        if selectedFilter == "All" {
            return allRepositories
        }
        return allRepositories.filter { $0.language == selectedFilter }
    }
    
    func fetchRepositories(username: String, token: String?) async {
        guard !username.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        async let starredRepositoriesTask = fetchStarredRepositoryNames(token: token)
        let starredRepositories = await starredRepositoriesTask
        
        let urlString = "https://api.github.com/users/\(username)/repos?sort=updated&per_page=100"
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = token, !token.isEmpty {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.addValue("GitMateApp", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            let decodedRepos = try JSONDecoder().decode([GitHubRepoDetailed].self, from: data)
            
            self.allRepositories = await withTaskGroup(of: (Int, RepositoryItem).self) { group in
                for (index, repo) in decodedRepos.enumerated() {
                    group.addTask {
                        var finalLang = repo.language
                        
                        if finalLang == nil {
                            finalLang = await self.fetchTopLanguage(urlString: repo.languagesUrl, token: token)
                        }
                        
                        let isReadmeRepo = repo.name.lowercased() == username.lowercased() || repo.name.lowercased().contains("readme")
                        let rawLang = finalLang ?? (isReadmeRepo ? "Md" : "Unknown")
                        let lang = rawLang.trimmingCharacters(in: .whitespacesAndNewlines)

                        let repositoryKey = "\(username.lowercased())/\(repo.name.lowercased())"
                        let isStarred = starredRepositories.contains(repositoryKey)

                        let item = await RepositoryItem(
                            owner: username,
                            name: repo.name,
                            description: repo.description ?? "No description provided.",
                            language: lang,
                            languageColor: self.getColorForLanguage(lang),
                            languageLogo: self.getLogoAssetIdentifier(lang),
                            stars: self.formatCount(repo.stargazersCount),
                            forks: self.formatCount(repo.forksCount),
                            updatedAgo: self.formatRelativeDate(repo.updatedAt),
                            isPrivate: repo.private,
                            iconName: repo.private ? "lock.fill" : "book.closed",
                            isStarred: isStarred
                        )
                        return (index, item)
                    }
                }
                
                var results: [(Int, RepositoryItem)] = []
                for await result in group {
                    results.append(result)
                }
                
                return results.sorted(by: { $0.0 < $1.0 }).map { $0.1 }
            }
            
            let uniqueLanguages = Set(self.allRepositories.map { $0.language })
                .filter { $0 != "Unknown" }
                .sorted()
            
            self.filters = ["All"] + uniqueLanguages
            
            if !self.filters.contains(self.selectedFilter) {
                self.selectedFilter = "All"
            }
            
        } catch {
            print("Error fetching repositories: \(error)")
            self.errorMessage = "Failed to load repositories."
        }
        
        isLoading = false
    }
    
    private func fetchStarredRepositoryNames(token: String?) async -> Set<String> {
        guard let token, !token.isEmpty else {
            return []
        }

        guard let url = URL(string: "https://api.github.com/user/starred?per_page=100") else {
            return []
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.addValue("GitMateApp", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return []
            }

            let repos = try JSONDecoder().decode([GitHubRepoDetailed].self, from: data)

            return Set(repos.map {
                "\($0.owner.login.lowercased())/\($0.name.lowercased())"
            })

        } catch {
            print("Failed to fetch starred repositories: \(error)")
            return []
        }
    }

    func toggleStar(owner: String, repo: String, isStarred: Bool, token: String?) async -> Bool {
        guard let token, !token.isEmpty else {
            return false
        }

        guard let url = URL(string: "https://api.github.com/user/starred/\(owner)/\(repo)") else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = isStarred ? "PUT" : "DELETE"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.addValue("GitMateApp", forHTTPHeaderField: "User-Agent")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }

            return httpResponse.statusCode == 204

        } catch {
            print("Failed to toggle star: \(error)")
            return false
        }
    }

    func deleteRepository(owner: String, repo: String, token: String?) async -> Bool {
        guard let token, !token.isEmpty else {
            return false
        }

        guard let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)") else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.addValue("GitMateApp", forHTTPHeaderField: "User-Agent")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }

            return (200...299).contains(httpResponse.statusCode)

        } catch {
            print("Failed to delete repository: \(error)")
            return false
        }
    }

    func removeRepository(_ repo: RepositoryItem) {
        allRepositories.removeAll { $0.id == repo.id }
    }
    
    func getLogoAssetIdentifier(_ language: String) -> String {
        return language.lowercased()
            .replacingOccurrences(of: "jupyter notebook", with: "jupyter")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "c++", with: "cpp")
            .replacingOccurrences(of: "c#", with: "csharp")
            .replacingOccurrences(of: "objective-c", with: "objc")
    }
    
    private func fetchTopLanguage(urlString: String, token: String?) async -> String? {
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = token, !token.isEmpty {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.addValue("GitMateApp", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }
            
            let languagesDict = try JSONDecoder().decode([String: Int].self, from: data)
            return languagesDict.max(by: { $0.value < $1.value })?.key
        } catch {
            return nil
        }
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        }
        return "\(count)"
    }
    
    private func formatRelativeDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "Unknown" }
        
        let formatter2 = RelativeDateTimeFormatter()
        formatter2.unitsStyle = .abbreviated
        return formatter2.localizedString(for: date, relativeTo: Date())
            .replacingOccurrences(of: " ago", with: "")
    }
    
    private func getColorForLanguage(_ language: String) -> Color {
        switch language.lowercased() {
        case "swift": return Color(red: 0.97, green: 0.33, blue: 0.23)
        case "objective-c", "objc": return Color(red: 0.26, green: 0.53, blue: 0.96)
        case "kotlin": return Color(red: 0.66, green: 0.29, blue: 0.99)
        case "dart": return Color(red: 0.0, green: 0.73, blue: 0.83)
        case "javascript", "js": return Color(red: 0.95, green: 0.83, blue: 0.22)
        case "typescript", "ts": return Color(red: 0.19, green: 0.47, blue: 0.78)
        case "html": return Color(red: 0.89, green: 0.3, blue: 0.14)
        case "css": return Color(red: 0.34, green: 0.22, blue: 0.58)
        case "scss", "sass": return Color(red: 0.77, green: 0.32, blue: 0.52)
        case "vue": return Color(red: 0.25, green: 0.73, blue: 0.52)
        case "svelte": return Color(red: 1.0, green: 0.24, blue: 0.0)
        case "python": return Color(red: 0.21, green: 0.45, blue: 0.65)
        case "java": return Color(red: 0.7, green: 0.27, blue: 0.13)
        case "c#", "csharp": return Color(red: 0.09, green: 0.55, blue: 0.16)
        case "c++": return Color(red: 0.95, green: 0.33, blue: 0.53)
        case "c": return Color(red: 0.33, green: 0.33, blue: 0.33)
        case "rust": return Color(red: 0.87, green: 0.65, blue: 0.52)
        case "go": return Color(red: 0.0, green: 0.68, blue: 0.82)
        case "php": return Color(red: 0.31, green: 0.36, blue: 0.58)
        case "ruby": return Color(red: 0.44, green: 0.08, blue: 0.09)
        case "shell", "bash", "zsh": return Color(red: 0.54, green: 0.88, blue: 0.32)
        case "dockerfile": return Color(red: 0.22, green: 0.56, blue: 0.98)
        case "yaml", "yml": return Color(red: 0.8, green: 0.8, blue: 0.8)
        case "sql", "plsql": return Color(red: 0.9, green: 0.38, blue: 0.23)
        case "jupyter notebook", "ipynb": return Color(red: 0.85, green: 0.43, blue: 0.22)
        case "r": return Color(red: 0.1, green: 0.55, blue: 0.91)
        case "markdown", "md": return Color(red: 0.03, green: 0.44, blue: 0.7)
        case "assembly", "asm": return Color(red: 0.43, green: 0.30, blue: 0.07)
        case "mustache": return Color(red: 0.45, green: 0.29, blue: 0.23)
        default: return .gray
        }
    }
}

struct RepositoriesView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @StateObject private var viewModel = RepositoriesViewModel()
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Repositories")
                        .font(.system(size: 34, weight: .bold, design: .default))
                        .foregroundStyle(.white)
                    
                    Text("Manage and explore your codebase.")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                if viewModel.isLoading && viewModel.allRepositories.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.filters, id: \.self) { filter in
                                Button {
                                    withAnimation {
                                        viewModel.selectedFilter = filter
                                    }
                                } label: {
                                    Group {
                                        if filter == "All" {
                                            Text(filter)
                                                .font(.system(size: 15, weight: .semibold))
                                        } else {
                                            let isMd = filter.lowercased() == "md" || filter.lowercased() == "markdown"
                                            Image(viewModel.getLogoAssetIdentifier(filter))
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: isMd ? 30 : 30, height: isMd ? 30 : 30)
                                        }
                                    }
                                    .foregroundStyle(viewModel.selectedFilter == filter ? Color.cyan : .white.opacity(0.8))
                                    .padding(.horizontal, filter == "All" ? 16 : 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        viewModel.selectedFilter == filter
                                        ? Color.cyan.opacity(0.15)
                                        : Color.white.opacity(0.05)
                                    )
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                viewModel.selectedFilter == filter
                                                ? Color.cyan
                                                : Color.white.opacity(0.1),
                                                lineWidth: 1
                                            )
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.filteredRepositories) { repo in
                            RepositoryCardView(
                                repo: repo,
                                onStar: { shouldStar in
                                    let success = await viewModel.toggleStar(
                                        owner: repo.owner,
                                        repo: repo.name,
                                        isStarred: shouldStar,
                                        token: sessionStore.savedAccessKey
                                    )

                                    if success {
                                        await MainActor.run {
                                            if let index = viewModel.allRepositories.firstIndex(where: { $0.id == repo.id }) {
                                                viewModel.allRepositories[index].isStarred = shouldStar
                                            }
                                        }
                                    }

                                    return success
                                },
                                onDelete: {
                                    let success = await viewModel.deleteRepository(
                                        owner: repo.owner,
                                        repo: repo.name,
                                        token: sessionStore.savedAccessKey
                                    )

                                    if success {
                                        await MainActor.run {
                                            viewModel.removeRepository(repo)
                                        }
                                    }

                                    return success
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 140)
                }
            }
        }
        .task {
            await viewModel.fetchRepositories(
                username: sessionStore.githubUsername,
                token: sessionStore.savedAccessKey
            )
        }
        .refreshable {
            await viewModel.fetchRepositories(
                username: sessionStore.githubUsername,
                token: sessionStore.savedAccessKey
            )
        }
    }
}

struct RepositoryCardView: View {
    let repo: RepositoryItem
    let onStar: (Bool) async -> Bool
    let onDelete: () async -> Bool

    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: repo.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.cyan)
                
                Text(repo.name)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Menu {
                    Button {
                        Task {
                            _ = await onStar(!repo.isStarred)
                        }
                    } label: {
                        Label(
                            repo.isStarred ? "Unstar Repository" : "Star Repository",
                            systemImage: repo.isStarred ? "star.slash" : "star"
                        )
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label(
                            "Delete Repository",
                            systemImage: "trash"
                        )
                    }

                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .rotationEffect(.degrees(90))
                }
                .confirmationDialog(
                    "Delete \(repo.name)?",
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Delete Repository", role: .destructive) {
                        Task {
                            _ = await onDelete()
                        }
                    }

                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This action permanently deletes the repository from GitHub and cannot be undone.")
                }
            }
            
            Text(repo.description)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.white.opacity(0.8))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(alignment: .center, spacing: 16) {
                
                if repo.language != "Unknown" {
                    let isMd = repo.languageLogo == "md" || repo.languageLogo == "markdown"
                    Image(repo.languageLogo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: isMd ? 45 : 30, height: isMd ? 45 : 30)
                        .padding(8)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: repo.isStarred ? "star.fill" : "star")
                        .font(.system(size: 12))
                    Text(repo.stars)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                }
                .foregroundStyle(repo.isStarred ? .yellow : .white.opacity(0.7))
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 13))
                    Text(repo.forks)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                }
                .foregroundStyle(.white.opacity(0.7))
                
                Spacer()
                
                Text("Updated \(repo.updatedAgo) ago")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Color(red: 0.05, green: 0.09, blue: 0.12).ignoresSafeArea()
        RepositoriesView()
            .environmentObject(SessionStore())
    }
}
