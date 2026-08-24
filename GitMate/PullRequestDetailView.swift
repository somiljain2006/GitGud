//
//  PullRequestDetailView.swift
//  GitMate
//
//  Created by somil jain on 25/08/26.
//

import SwiftUI

struct PullRequestDetailView: View {
    let reference: PullRequestReference
    let token: String?

    @State private var pr: PullRequestDetail?
    @State private var files: [PullRequestFile] = []
    @State private var isLoading = true
    @State private var hasError = false
    @State private var commits: [PullRequestCommit] = []
    @State private var reviewComments: [PullRequestReviewComment] = []
    @State private var expandedReviewCommentIDs: Set<Int> = []
    @State private var replyingToCommentID: Int?
    @State private var replyText: String = ""
    @State private var isPostingReply = false
    @State private var replyError: String?
    @State private var resolvingCommentIDs: Set<Int> = []
    @State private var expandedResolvedThreadIDs: Set<String> = []

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
                    Divider()
                        .background(.white.opacity(0.1))
                    reviewCommentsSection()
                    Divider()
                        .background(.white.opacity(0.1))
                    commitsSection()
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

    private func reviewCommentsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Review Comments")
                .font(.headline)
                .foregroundStyle(.white)

            if reviewComments.isEmpty {
                Text("No review comments.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                ForEach(rootReviewComments) { comment in
                    reviewThread(comment)
                }
            }
        }
    }

    private var rootReviewComments: [PullRequestReviewComment] {
        reviewComments.filter { $0.inReplyToId == nil }
    }

    private func commitsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Commits")
                .font(.headline)
                .foregroundStyle(.white)

            if commits.isEmpty {
                Text("No commits found.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                ForEach(commits) { commit in
                    PRCommitRowView(commit: commit)
                }
            }
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

        async let fetchedCommits = service.fetchPullRequestCommits(
            owner: reference.owner,
            repo: reference.repository,
            number: reference.number,
            token: token
        )

        async let fetchedReviewComments = service.fetchPullRequestReviewComments(
            owner: reference.owner,
            repo: reference.repository,
            number: reference.number,
            token: token
        )

        let (
            prResult,
            filesResult,
            commitsResult,
            reviewCommentsResult
        ) = await(
            fetchedPR,
            fetchedFiles,
            fetchedCommits,
            fetchedReviewComments
        )

        if let prResult {
            pr = prResult
            files = filesResult
            commits = commitsResult
            reviewComments = reviewCommentsResult
        } else {
            hasError = true
        }

        isLoading = false
    }

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

    struct PRStateDisplay {
        let title: String
        let color: Color
        let icon: String
    }

    @ViewBuilder
    private func prStateBadge(pr: PullRequestDetail) -> some View {
        let display = stateProperties(for: pr)

        HStack(spacing: 4) {
            Image(systemName: display.icon)
                .font(.caption)
            Text(display.title)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(display.color.opacity(0.2))
        .foregroundStyle(display.color)
        .clipShape(Capsule())
    }

    private func stateProperties(for pr: PullRequestDetail) -> PRStateDisplay {
        if pr.mergedAt != nil {
            return PRStateDisplay(title: "Merged", color: .purple, icon: "arrow.triangle.merge")
        } else if pr.state == "closed" {
            return PRStateDisplay(title: "Closed", color: .red, icon: "xmark.circle")
        } else if pr.draft == true {
            return PRStateDisplay(title: "Draft", color: .gray, icon: "doc.text")
        } else {
            return PRStateDisplay(title: "Open", color: .green, icon: "arrow.triangle.branch")
        }
    }

    private func descriptionSection(pr: PullRequestDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
                .foregroundStyle(.white)

            if let body = pr.body, !body.isEmpty {
                MarkdownText(
                    body,
                    color: .white.opacity(0.8)
                )
                .font(.body)
            } else {
                Text("No description provided.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.5))
                    .italic()
            }
        }
    }

    private func statsSection(pr: PullRequestDetail) -> some View {
        HStack(spacing: 24) {
            statItem(title: "Additions", value: "+\(pr.additions)", color: .green)
            statItem(title: "Deletions", value: "-\(pr.deletions)", color: .red)
            statItem(title: "Files", value: "\(pr.changedFiles)", color: .white)
            statItem(title: "Commits", value: "\(pr.commits)", color: .white)
            statItem(title: "Comments", value: "\(pr.comments + pr.reviewComments)", color: .white)
        }
    }

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

    private func filesSection() -> some View {
        NavigationLink {
            PullRequestFilesView(
                files: files,
                pr: pr,
                token: token,
                onCommitSuccess: {
                    Task {
                        await loadData()
                    }
                }
            )
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.cyan)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Files Changed")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("\(files.count) \(files.count == 1 ? "file" : "files") changed")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.04))
            .clipShape(
                RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        Color.white.opacity(0.06),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func reviewResolutionButton(
        for comment: PullRequestReviewComment
    ) -> some View {
        HStack {
            Spacer()

            if resolvingCommentIDs.contains(comment.id) {
                ProgressView()
                    .tint(.cyan)

                Text(
                    comment.isResolved
                        ? "Unresolving..."
                        : "Resolving..."
                )
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))

            } else {
                Button {
                    Task {
                        await toggleReviewResolution(for: comment)
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(
                            systemName: comment.isResolved
                                ? "arrow.uturn.backward"
                                : "checkmark.circle"
                        )

                        Text(
                            comment.isResolved
                                ? "Unresolve"
                                : "Resolve"
                        )
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(
                        comment.isResolved
                            ? .orange
                            : .green
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 4)
    }

    private func toggleReviewResolution(
        for comment: PullRequestReviewComment
    ) async {
        guard let threadID = comment.nodeID else {
            return
        }

        guard !resolvingCommentIDs.contains(comment.id) else {
            return
        }

        resolvingCommentIDs.insert(comment.id)

        let newResolvedState = !comment.isResolved

        let success = await service.setReviewThreadResolved(
            threadID: threadID,
            resolved: newResolvedState,
            token: token
        )

        if success {
            reviewComments = reviewComments.map { item in
                guard item.nodeID == threadID else {
                    return item
                }

                var updated = item
                updated.isResolved = newResolvedState
                return updated
            }
        }

        resolvingCommentIDs.remove(comment.id)
    }

    @ViewBuilder
    private func fileDestination(for file: PullRequestFile) -> some View {
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
    }

    @ViewBuilder
    private func reviewThread(
        _ comment: PullRequestReviewComment
    ) -> some View {
        let replies = reviewComments.filter {
            $0.inReplyToId == comment.id
        }

        if comment.isResolved {
            resolvedReviewThread(
                comment: comment,
                replies: replies
            )
        } else {
            unresolvedReviewThread(
                comment: comment,
                replies: replies
            )
        }
    }

    private func unresolvedReviewThread(
        comment: PullRequestReviewComment,
        replies: [PullRequestReviewComment]
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            reviewCommentBlock(comment)

            ForEach(replies) { reply in
                reviewReplyBlock(reply)
            }
        }
        .background(Color.white.opacity(0.04))
        .clipShape(
            RoundedRectangle(cornerRadius: 12)
        )
    }

    private func resolvedReviewThread(
        comment: PullRequestReviewComment,
        replies: [PullRequestReviewComment]
    ) -> some View {
        let threadID = comment.nodeID ?? String(comment.id)
        let isExpanded = expandedResolvedThreadIDs.contains(threadID)

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                toggleResolvedThread(threadID)
            } label: {
                HStack(spacing: 8) {
                    Image(
                        systemName: isExpanded
                            ? "chevron.down"
                            : "chevron.right"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)

                    Text("Review thread resolved")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(12)

            if isExpanded {
                reviewCommentBlockWithoutResolution(comment)

                ForEach(replies) { reply in
                    reviewReplyBlock(reply)
                }
            }

            reviewResolutionButton(for: comment)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
        }
        .background(Color.green.opacity(0.04))
        .clipShape(
            RoundedRectangle(cornerRadius: 12)
        )
    }

    private func reviewCommentContent(
        _ comment: PullRequestReviewComment,
        showResolution: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            reviewCommentLocation(comment)

            reviewCommentDiff(comment)

            reviewCommentHeader(comment)

            MarkdownText(
                comment.body,
                color: .white.opacity(0.9)
            )
            .font(.body)

            if showResolution {
                reviewResolutionButton(for: comment)
            }

            reviewCommentReplyAction(comment)
        }
        .padding(12)
    }

    @ViewBuilder
    private func reviewCommentLocation(
        _ comment: PullRequestReviewComment
    ) -> some View {
        if let path = comment.path {
            HStack(spacing: 6) {
                Image(systemName: "doc.text")
                    .font(.caption)

                Text(path)
                    .font(.caption.monospaced())
                    .foregroundStyle(.cyan)

                if let line = comment.line {
                    Text(":\(line)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()
            }
        }
    }

    @ViewBuilder
    private func reviewCommentDiff(
        _ comment: PullRequestReviewComment
    ) -> some View {
        if let diffHunk = comment.diffHunk,
           !diffHunk.trimmingCharacters(
               in: .whitespacesAndNewlines
           ).isEmpty
        {
            Button {
                toggleReviewCommentDiff(comment.id)
            } label: {
                HStack(spacing: 6) {
                    Image(
                        systemName: expandedReviewCommentIDs.contains(comment.id)
                            ? "chevron.down"
                            : "chevron.right"
                    )
                    .font(.caption.weight(.semibold))

                    Text("View code context")
                        .font(.caption.weight(.medium))

                    Spacer()
                }
                .foregroundStyle(.white.opacity(0.7))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expandedReviewCommentIDs.contains(comment.id) {
                diffView(diffHunk)
                    .textSelection(.enabled)
                    .transition(.opacity)
            }
        } else {
            Text("Code context unavailable")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .padding(8)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .background(Color.black.opacity(0.2))
                .clipShape(
                    RoundedRectangle(cornerRadius: 8)
                )
        }
    }

    @ViewBuilder
    private func reviewCommentReplyAction(
        _ comment: PullRequestReviewComment
    ) -> some View {
        if replyingToCommentID == comment.id {
            replyComposer(for: comment)
        } else {
            Button {
                startReply(to: comment)
            } label: {
                Label(
                    "Reply",
                    systemImage: "arrowshape.turn.up.left"
                )
                .font(.caption.weight(.medium))
                .foregroundStyle(.cyan)
            }
            .buttonStyle(.plain)
        }
    }

    private func reviewCommentBlockWithoutResolution(
        _ comment: PullRequestReviewComment
    ) -> some View {
        reviewCommentContent(
            comment,
            showResolution: false
        )
    }

    private func reviewCommentBlock(
        _ comment: PullRequestReviewComment
    ) -> some View {
        reviewCommentContent(
            comment,
            showResolution: true
        )
    }

    private func toggleResolvedThread(_ threadID: String) {
        if expandedResolvedThreadIDs.contains(threadID) {
            expandedResolvedThreadIDs.remove(threadID)
        } else {
            expandedResolvedThreadIDs.insert(threadID)
        }
    }

    private func replyComposer(
        for comment: PullRequestReviewComment
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            replyTextEditor()

            if let replyError {
                Text(replyError)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            replyActions(for: comment)
        }
        .padding(10)
        .background(Color.black.opacity(0.15))
        .clipShape(
            RoundedRectangle(cornerRadius: 10)
        )
    }

    private func replyTextEditor() -> some View {
        TextEditor(text: $replyText)
            .font(.body)
            .foregroundStyle(.white)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 80, maxHeight: 140)
            .padding(8)
            .background(Color.white.opacity(0.06))
            .clipShape(
                RoundedRectangle(cornerRadius: 10)
            )
    }

    private func replyActions(
        for comment: PullRequestReviewComment
    ) -> some View {
        HStack {
            Button("Cancel") {
                cancelReply()
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.white.opacity(0.6))

            Spacer()

            if isPostingReply {
                ProgressView()
                    .tint(.cyan)
            } else {
                postReplyButton(for: comment)
            }
        }
    }

    private func postReplyButton(
        for comment: PullRequestReviewComment
    ) -> some View {
        let isEmpty = replyText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty

        return Button("Reply") {
            Task {
                await postReply(to: comment)
            }
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(
            isEmpty
                ? .white.opacity(0.3)
                : .cyan
        )
        .disabled(isEmpty)
    }

    private func startReply(
        to comment: PullRequestReviewComment
    ) {
        replyingToCommentID = comment.id
        replyText = ""
        replyError = nil
    }

    private func cancelReply() {
        replyingToCommentID = nil
        replyText = ""
        replyError = nil
    }

    private func postReply(to comment: PullRequestReviewComment) async {
        let body = replyText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !body.isEmpty else {
            return
        }

        isPostingReply = true
        replyError = nil

        let request = CommentReplyRequest(
            owner: reference.owner,
            repo: reference.repository,
            pullNumber: reference.number,
            commentID: comment.id,
            body: body,
            token: token
        )

        let newReply = await service.replyToPullRequestReviewComment(request: request)

        if let newReply {
            reviewComments.append(newReply)

            replyingToCommentID = nil
            replyText = ""
        } else {
            replyError = "Unable to post reply. Please try again."
        }

        isPostingReply = false
    }

    private func toggleReviewCommentDiff(_ commentID: Int) {
        if expandedReviewCommentIDs.contains(commentID) {
            expandedReviewCommentIDs.remove(commentID)
        } else {
            expandedReviewCommentIDs.insert(commentID)
        }
    }

    private func reviewCommentHeader(
        _ comment: PullRequestReviewComment
    ) -> some View {
        PRReviewCommentHeaderView(comment: comment)
    }

    private func reviewReplyBlock(
        _ reply: PullRequestReviewComment
    ) -> some View {
        PRReviewReplyBlockView(reply: reply)
    }

    func diffView(_ patch: String) -> some View {
        PRDiffView(patch: patch)
    }
}
