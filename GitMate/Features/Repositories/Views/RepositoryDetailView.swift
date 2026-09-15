//
//  RepositoryDetailView.swift
//  GitMate
//
//  Created by somil jain on 13/09/26.
//

import SwiftUI

struct RepositoryDetailView: View {
    let owner: String
    let repo: String

    @EnvironmentObject var sessionStore: SessionStore
    @State private var detail: GraphQLRepositoryDetail?
    @State private var isLoading = true

    @State private var branches: [GitHubBranch] = []
    @State private var selectedBranch: String = ""
    @State private var rootFiles: [GitHubDirectoryItem] = []
    @State private var readmeContent: String?
    @State private var commits: [PullRequestCommit] = []

    @State private var isStarred = false
    @State private var isWatching = false
    @State private var actionLoading = false

    private let service = GitHubService()

    var canCommit: Bool {
        detail?.viewerPermission == "ADMIN" || detail?.viewerPermission == "MAINTAIN" || detail?.viewerPermission == "WRITE"
    }

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.09, blue: 0.12).ignoresSafeArea()

            if isLoading {
                ProgressView().tint(.cyan)
            } else if let detail = detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection(detail: detail)
                        actionButtons
                        statsSection(detail: detail)

                        Divider().background(Color.white.opacity(0.1))

                        branchSelector

                        if !commits.isEmpty {
                            commitSummary
                        }

                        fileBrowserSection

                        if let readme = readmeContent {
                            readmeSection(content: readme)
                        }

                        if let languages = detail.languages, let edges = languages.edges, !edges.isEmpty {
                            languageSection(languages: languages)
                        }
                    }
                    .padding()
                }
            } else {
                Text("Failed to load repository.")
                    .foregroundStyle(.red)
            }
        }
        .navigationTitle(repo)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
    }

    private func headerSection(detail: GraphQLRepositoryDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: detail.isPrivate ? "lock.fill" : "book.closed")
                    .foregroundStyle(.cyan)
                    .font(.title2)
                Text(detail.nameWithOwner)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Spacer()
                Text(detail.isPrivate ? "Private" : "Public")
                    .font(.caption.bold())
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .overlay(Capsule().stroke(Color.white.opacity(0.2)))
                    .foregroundStyle(.gray)
            }

            if let desc = detail.description {
                Text(desc)
                    .foregroundStyle(.white.opacity(0.8))
            }

            HStack(spacing: 16) {
                if let homepage = detail.homepageUrl, !homepage.isEmpty, let url = URL(string: homepage) {
                    Link(destination: url) {
                        Label("Website", systemImage: "link")
                            .font(.caption)
                    }
                }
                if let license = detail.licenseInfo {
                    Label(license.name, systemImage: "checkmark.seal")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack {
            Button(action: toggleStar) {
                Label(isStarred ? "Starred" : "Star", systemImage: isStarred ? "star.fill" : "star")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(BorderedButtonStyle())
            .tint(isStarred ? .yellow : .gray)
            .disabled(actionLoading)

            Button(action: toggleWatch) {
                Label(isWatching ? "Watching" : "Watch", systemImage: isWatching ? "eye.fill" : "eye")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(BorderedButtonStyle())
            .tint(isWatching ? .cyan : .gray)
            .disabled(actionLoading)

            Button(action: forkRepo) {
                Label("Fork", systemImage: "arrow.triangle.branch")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(BorderedButtonStyle())
            .tint(.gray)
            .disabled(actionLoading)
        }
    }

    private func statsSection(detail: GraphQLRepositoryDetail) -> some View {
        HStack(spacing: 24) {
            statItem(icon: "star", value: detail.stargazerCount, label: "Stars")
            statItem(icon: "arrow.triangle.branch", value: detail.forkCount, label: "Forks")
            statItem(icon: "eye", value: detail.watchers?.totalCount ?? 0, label: "Watchers")

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(detail.issues?.totalCount ?? 0) Issues")
                    .font(.caption)
                    .foregroundStyle(.gray)
                Text("\(detail.pullRequests?.totalCount ?? 0) PRs")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
    }

    private func statItem(icon: String, value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text("\(value)")
                    .bold()
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.gray)
        }
        .foregroundStyle(.white)
    }

    private var branchSelector: some View {
        HStack {
            Image(systemName: "arrow.triangle.branch")
                .foregroundStyle(.cyan)

            Menu {
                ForEach(branches) { branch in
                    Button(branch.name) {
                        selectedBranch = branch.name
                        Task { await loadBranchSpecificData() }
                    }
                }
            } label: {
                Text(selectedBranch.isEmpty ? "Select Branch" : selectedBranch)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var commitSummary: some View {
        NavigationLink(destination: CommitListView(owner: owner, repo: repo, branch: selectedBranch)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(commits.first?.commit.message.components(separatedBy: "\n").first ?? "")
                        .lineLimit(1)
                        .foregroundStyle(.white)
                    Text("Latest commit by \(commits.first?.author?.login ?? "Unknown")")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var fileBrowserSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Files")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                NavigationLink(destination: RepositoryFileBrowserView(owner: owner, repo: repo, branch: selectedBranch, path: "", canCommit: canCommit)) {
                    Text("View all")
                        .font(.caption)
                        .foregroundStyle(.cyan)
                }
            }

            VStack(spacing: 0) {
                ForEach(rootFiles.prefix(5)) { file in
                    NavigationLink(destination: file.type == "dir" ? AnyView(RepositoryFileBrowserView(owner: owner, repo: repo, branch: selectedBranch, path: file.path, canCommit: canCommit)) : AnyView(PullRequestFileEditorView(headOwner: owner, headRepo: repo, headBranch: selectedBranch, filePath: file.path, token: sessionStore.savedAccessKey, isPullRequest: false, canCommit: canCommit))) {
                        HStack {
                            Image(systemName: file.type == "dir" ? "folder.fill" : "doc.text")
                                .foregroundStyle(file.type == "dir" ? .blue : .gray)
                            Text(file.name)
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.gray)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    }
                    if file.id != rootFiles.prefix(5).last?.id {
                        Divider().background(Color.white.opacity(0.1))
                    }
                }
            }
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func readmeSection(content: String) -> some View {
        let rawBaseURL = URL(string: "https://raw.githubusercontent.com/\(owner)/\(repo)/\(selectedBranch)/")
        return VStack(alignment: .leading, spacing: 8) {
            Text("README.md")
                .font(.headline)
                .foregroundStyle(.white)

            MarkdownText(content, baseURL: rawBaseURL)
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func languageSection(languages: LanguagesNode) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Languages")
                .font(.headline)
                .foregroundStyle(.white)

            GeometryReader { proxy in
                HStack(spacing: 0) {
                    let totalSize = CGFloat(max(1, languages.totalSize))
                    ForEach(languages.edges ?? [], id: \.node?.name) { edge in
                        Rectangle()
                            .fill(Color(hex: edge.node?.color ?? "#cccccc"))
                            .frame(width: max(0, proxy.size.width * CGFloat(edge.size) / totalSize))
                    }
                }
            }
            .frame(height: 8)
            .clipShape(Capsule())

            FlowLayout(spacing: 8) {
                ForEach(languages.edges ?? [], id: \.node?.name) { edge in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: edge.node?.color ?? "#cccccc"))
                            .frame(width: 8, height: 8)
                        Text(edge.node?.name ?? "")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        Text(String(format: "%.1f%%", Double(edge.size) / Double(max(1, languages.totalSize)) * 100))
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
    }

    private func loadData() async {
        isLoading = true
        async let detailTask = service.fetchRepositoryDetail(owner: owner, repo: repo, token: sessionStore.savedAccessKey)
        async let branchesTask = service.fetchBranches(owner: owner, repo: repo, token: sessionStore.savedAccessKey)

        detail = await detailTask
        branches = await branchesTask

        isStarred = detail?.viewerHasStarred ?? false
        isWatching = detail?.viewerSubscription == "SUBSCRIBED"

        if let defaultBranch = detail?.defaultBranchRef?.name {
            selectedBranch = defaultBranch
        } else if let first = branches.first {
            selectedBranch = first.name
        }

        await loadBranchSpecificData()
        isLoading = false
    }

    private func loadBranchSpecificData() async {
        async let commitsTask = service.fetchRepositoryCommits(owner: owner, repo: repo, branch: selectedBranch, token: sessionStore.savedAccessKey)
        async let rootTask = service.fetchDirectoryContents(owner: owner, repo: repo, path: "", branch: selectedBranch, token: sessionStore.savedAccessKey)

        if let readmeFile = await service.fetchFileContent(owner: owner, repo: repo, path: "README.md", branch: selectedBranch, token: sessionStore.savedAccessKey) {
            readmeContent = readmeFile.decodedContent
        } else if let readmeFile = await service.fetchFileContent(owner: owner, repo: repo, path: "readme.md", branch: selectedBranch, token: sessionStore.savedAccessKey) {
            readmeContent = readmeFile.decodedContent
        } else {
            readmeContent = nil
        }

        commits = await commitsTask
        rootFiles = await rootTask ?? []
        rootFiles.sort {
            if $0.type == $1.type {
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            return $0.type == "dir"
        }
    }

    private func toggleStar() {
        guard !actionLoading else { return }
        actionLoading = true
        Task {
            let success = await service.toggleStar(owner: owner, repo: repo, isStarred: !isStarred, token: sessionStore.savedAccessKey)
            if success {
                isStarred.toggle()
            }
            actionLoading = false
        }
    }

    private func toggleWatch() {
        guard !actionLoading else { return }
        actionLoading = true
        Task {
            let success = await service.toggleWatch(owner: owner, repo: repo, isWatching: !isWatching, token: sessionStore.savedAccessKey)
            if success {
                isWatching.toggle()
            }
            actionLoading = false
        }
    }

    private func forkRepo() {
        guard !actionLoading else { return }
        actionLoading = true
        Task {
            _ = await service.forkRepository(owner: owner, repo: repo, token: sessionStore.savedAccessKey)
            actionLoading = false
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var height: CGFloat = 0
        for row in rows {
            height += row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            height += spacing
        }
        return CGSize(width: proposal.width ?? 0, height: height - spacing)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var currentY = bounds.minY
        for row in rows {
            var currentX = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for view in row {
                let size = view.sizeThatFits(.unspecified)
                view.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
                currentX += size.width + spacing
            }
            currentY += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var width: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if width + size.width > maxWidth, let lastRow = rows.last, !lastRow.isEmpty {
                rows.append([view])
                width = size.width + spacing
            } else {
                rows[rows.count - 1].append(view)
                width += size.width + spacing
            }
        }
        return rows
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted
        )

        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let alpha: UInt64
        let red: UInt64
        let green: UInt64
        let blue: UInt64

        switch hex.count {
        case 3:
            (alpha, red, green, blue) = (
                255,
                (int >> 8) * 17,
                (int >> 4 & 0xF) * 17,
                (int & 0xF) * 17
            )

        case 6:
            (alpha, red, green, blue) = (
                255,
                int >> 16,
                int >> 8 & 0xFF,
                int & 0xFF
            )

        case 8:
            (alpha, red, green, blue) = (
                int >> 24,
                int >> 16 & 0xFF,
                int >> 8 & 0xFF,
                int & 0xFF
            )

        default:
            (alpha, red, green, blue) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}
