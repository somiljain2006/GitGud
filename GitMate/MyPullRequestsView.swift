//
//  MyPullRequestsView.swift
//  GitMate
//
//  Created by somil jain on 23/08/26.
//

import SwiftUI

struct MyPullRequest: Identifiable, Codable {
    let id: Int
    let number: Int
    let title: String
    let state: String
    let body: String?
    let htmlURL: String
    let repositoryName: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case number
        case title
        case state
        case body
        case htmlURL = "html_url"
        case repositoryName
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct MyPullRequestsView: View {
    let pullRequests: [MyPullRequest]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if pullRequests.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 40))
                                .foregroundStyle(.green)

                            Text("No pull requests opened by you")
                                .font(.headline)
                                .foregroundStyle(.white)

                            Text("Pull requests you create will appear here.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    } else {
                        ForEach(pullRequests) { pullRequest in
                            let parts = pullRequest.repositoryName.split(separator: "/")
                            let owner = !parts.isEmpty ? String(parts[0]) : ""
                            let repo = parts.count > 1 ? String(parts[1]) : pullRequest.repositoryName
                            
                            NavigationLink {
                                PullRequestDetailView(
                                    reference: PullRequestReference(
                                        owner: owner,
                                        repository: repo,
                                        number: pullRequest.number
                                    ),
                                    token: session.savedAccessKey
                                )
                            } label: {
                                PullRequestCard(pullRequest: pullRequest)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(
                Color(
                    red: 0.05,
                    green: 0.09,
                    blue: 0.12
                )
                .ignoresSafeArea()
            )
            .navigationTitle("My Pull Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct PullRequestCard: View {
    let pullRequest: MyPullRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(
                        systemName: pullRequest.state == "open"
                            ? "arrow.triangle.branch"
                            : "checkmark.circle.fill"
                    )
                    .foregroundStyle(
                        pullRequest.state == "open"
                            ? .green
                            : .purple
                    )

                    Text("#\(pullRequest.number)")
                        .font(
                            .system(
                                size: 13,
                                weight: .medium,
                                design: .monospaced
                            )
                        )
                        .foregroundStyle(.white.opacity(0.5))

                    Spacer()

                    Text(pullRequest.repositoryName)
                        .font(
                            .system(
                                size: 12,
                                design: .monospaced
                            )
                        )
                        .foregroundStyle(.white.opacity(0.5))
                }

                Text(pullRequest.title)
                    .font(
                        .system(
                            size: 17,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)

                if let body = pullRequest.body,
                   !body.isEmpty {
                    Text(body)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.white.opacity(0.04))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
                .stroke(
                    Color.white.opacity(0.06),
                    lineWidth: 1
                )
            )
        }
    }


struct PullRequestDetailView: View {
    let reference: PullRequestReference
    let token: String?
    
    @State private var pr: PullRequestDetail?
    @State private var files: [PullRequestFile] = []
    @State private var isLoading = true
    @State private var hasError = false
    
    private let service = GitHubService()
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if isLoading {
                    ProgressView()
                        .tint(.cyan)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 50)
                } else if hasError || pr == nil {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundStyle(.orange)
                        
                        Text("Unable to load pull request")
                            .font(.headline)
                        
                        Button("Retry") {
                            Task {
                                await loadData()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 50)
                } else if let pr = pr {
                    headerSection(pr: pr)
                    Divider().background(.white.opacity(0.1))
                    descriptionSection(pr: pr)
                    Divider().background(.white.opacity(0.1))
                    statsSection(pr: pr)
                    Divider().background(.white.opacity(0.1))
                    filesSection()
                }
            }
            .padding(20)
        }
        .background(
            Color(red: 0.05, green: 0.09, blue: 0.12)
                .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if let pr = pr, let url = URL(string: pr.htmlUrl) {
                    Button {
                        openURL(url)
                    } label: {
                        Image(systemName: "safari")
                    }
                }
            }
        }
        .task {
            await loadData()
        }
    }
    
    private func loadData() async {
        isLoading = true
        hasError = false
        
        async let fetchedPR = service.fetchPullRequestDetail(
            owner: reference.owner,
            repo: reference.repository,
            number: reference.number,
            token: token
        )
        
        async let fetchedFiles = service.fetchPullRequestFiles(
            owner: reference.owner,
            repo: reference.repository,
            number: reference.number,
            token: token
        )
        
        let (prResult, filesResult) = await (fetchedPR, fetchedFiles)
        
        if let prResult = prResult {
            self.pr = prResult
            self.files = filesResult
        } else {
            self.hasError = true
        }
        
        isLoading = false
    }
    
    @ViewBuilder
    private func headerSection(pr: PullRequestDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(reference.owner)/\(reference.repository) #\(pr.number)")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
            
            Text(pr.title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
            
            HStack(spacing: 8) {
                prStateBadge(pr: pr)
                
                AsyncImage(url: URL(string: pr.user.avatarUrl)) { image in
                    image.resizable()
                } placeholder: {
                    Circle().fill(.gray.opacity(0.3))
                }
                .frame(width: 24, height: 24)
                .clipShape(Circle())
                
                Text(pr.user.login)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                
                Spacer()
            }
            
            Text("Opened \(RelativeDateFormatter.relativeString(from: pr.createdAt))")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
    }
    
    @ViewBuilder
    private func prStateBadge(pr: PullRequestDetail) -> some View {
        let (title, color, icon) = stateProperties(for: pr)
        
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(title)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
    
    private func stateProperties(for pr: PullRequestDetail) -> (String, Color, String) {
        if pr.mergedAt != nil {
            return ("Merged", .purple, "arrow.triangle.merge")
        } else if pr.state == "closed" {
            return ("Closed", .red, "xmark.circle")
        } else if pr.draft == true {
            return ("Draft", .gray, "doc.text")
        } else {
            return ("Open", .green, "arrow.triangle.branch")
        }
    }
    
    @ViewBuilder
    private func descriptionSection(pr: PullRequestDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
                .foregroundStyle(.white)
            
            if let body = pr.body, !body.isEmpty {
                Text(body)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
            } else {
                Text("No description provided.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.5))
                    .italic()
            }
        }
    }
    
    @ViewBuilder
    private func statsSection(pr: PullRequestDetail) -> some View {
        HStack(spacing: 24) {
            statItem(title: "Additions", value: "+\(pr.additions)", color: .green)
            statItem(title: "Deletions", value: "-\(pr.deletions)", color: .red)
            statItem(title: "Files", value: "\(pr.changedFiles)", color: .white)
            statItem(title: "Commits", value: "\(pr.commits)", color: .white)
            statItem(title: "Comments", value: "\(pr.comments + pr.reviewComments)", color: .white)
        }
    }
    
    @ViewBuilder
    private func statItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
    }
    
    @ViewBuilder
    private func filesSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Files Changed")
                .font(.headline)
                .foregroundStyle(.white)
            
            if files.isEmpty {
                Text("No files changed.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                ForEach(files) { file in
                    NavigationLink {
                        if let headRepo = pr?.head.repo, let headRef = pr?.head.ref {
                            PullRequestFileEditorView(
                                headOwner: headRepo.owner.login,
                                headRepo: headRepo.name,
                                headBranch: headRef,
                                filePath: file.filename,
                                token: token,
                                onCommitSuccess: {
                                    Task { await loadData() }
                                }
                            )
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.orange)
                                Text("Cannot edit this file.")
                                Text("Missing repository head information.")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(file.filename)
                                    .font(.system(size: 14, design: .monospaced))
                                    .foregroundStyle(.cyan)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                
                                Spacer()
                                
                                Text("+\(file.additions)")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.green)
                                Text("-\(file.deletions)")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.red)
                            }
                            
                            if let patch = file.patch {
                                DisclosureGroup("View diff") {
                                    Text(patch)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.8))
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.black.opacity(0.3))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .tint(.cyan)
                                .font(.caption)
                            }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct PullRequestFileEditorView: View {

    let headOwner: String
    let headRepo: String
    let headBranch: String
    let filePath: String
    let token: String?

    var onCommitSuccess: (() -> Void)?


    @State private var fileContent: GitHubFileContent?
    @State private var editedText: String = ""
    @State private var isLoading = true
    @State private var loadError: String?

    @State private var isCommitting = false
    @State private var showCommitSheet = false
    @State private var commitMessage: String = ""
    @State private var commitError: String?

    private let service = GitHubService()
    @Environment(\.dismiss) private var dismiss

    private var filename: String {
        filePath.components(separatedBy: "/").last ?? filePath
    }

    private var hasChanges: Bool {
        guard let original = fileContent?.decodedContent else { return false }
        return editedText != original
    }

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.09, blue: 0.12).ignoresSafeArea()
            content
        }
        .navigationTitle(filename)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarItems }
        .sheet(isPresented: $showCommitSheet) {
            commitSheetView
        }
        .task { await loadFile() }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView()
                .tint(.cyan)
        } else if let error = loadError {
            editorErrorView(message: error) {
                Task { await loadFile() }
            }
        } else if fileContent?.decodedContent == nil {
            editorErrorView(message: "This file appears to be binary and cannot be edited as text.") {
                dismiss()
            }
        } else {
            editorBody
        }
    }

    private var editorBody: some View {
        TextEditor(text: $editedText)
            .font(.system(size: 13, design: .monospaced))
            .foregroundStyle(.white)
            .scrollContentBackground(.hidden)
            .background(Color(red: 0.05, green: 0.09, blue: 0.12))
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Close") { dismiss() }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                commitMessage = "Update \(filename)"
                commitError = nil
                showCommitSheet = true
            } label: {
                Label("Commit", systemImage: "arrow.up.circle")
                    .foregroundStyle(hasChanges ? Color.cyan : Color.white.opacity(0.3))
            }
            .disabled(!hasChanges || isLoading || isCommitting)
        }
    }

    private var commitSheetView: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.09, blue: 0.12).ignoresSafeArea()
                commitSheetContent
            }
            .navigationTitle("Commit Changes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showCommitSheet = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isCommitting {
                        ProgressView().tint(.cyan)
                    } else {
                        Button("Commit") {
                            Task { await performCommit() }
                        }
                        .foregroundStyle(commitMessage.isEmpty ? Color.white.opacity(0.3) : Color.cyan)
                        .disabled(commitMessage.isEmpty || isCommitting)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var commitSheetContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("COMMIT MESSAGE")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))

                TextField("Describe your change…", text: $commitMessage)
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("COMMITTING TO")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))

                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.branch")
                        .foregroundStyle(.cyan)
                        .font(.caption)
                    Text("\(headOwner)/\(headRepo)")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                }
                HStack(spacing: 6) {
                    Image(systemName: "point.3.connected.trianglepath.dotted")
                        .foregroundStyle(.cyan)
                        .font(.caption)
                    Text(headBranch)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                }

                Text("This will update the Pull Request automatically.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 2)
            }
            .padding(14)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if let err = commitError {
                Label(err, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Spacer()
        }
        .padding(20)
    }

    private func loadFile() async {
        isLoading = true
        loadError = nil
        let result = await service.fetchFileContent(
            owner: headOwner,
            repo: headRepo,
            path: filePath,
            branch: headBranch,
            token: token
        )
        if let result {
            fileContent = result
            editedText = result.decodedContent ?? ""
        } else {
            loadError = "Could not load file. Check your token and repository access."
        }
        isLoading = false
    }

    private func performCommit() async {
        guard let sha = fileContent?.sha else { return }
        isCommitting = true
        commitError = nil

        let result = await service.updateFile(
            owner: headOwner,
            repo: headRepo,
            path: filePath,
            branch: headBranch,
            sha: sha,
            content: editedText,
            commitMessage: commitMessage,
            token: token
        )

        switch result {
        case .success:
            showCommitSheet = false
            onCommitSuccess?()
            dismiss()
        case .failure(let err):
            commitError = err.localizedDescription
        }

        isCommitting = false
    }

    @ViewBuilder
    private func editorErrorView(message: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: action) {
                Text("OK")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.cyan.opacity(0.2))
                    .foregroundStyle(.cyan)
                    .clipShape(Capsule())
            }
        }
    }
}
