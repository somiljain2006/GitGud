//
//  IssueDetailView.swift
//  GitMate
//
//  Created by somil jain on 01/09/26.
//

import SwiftUI

struct IssueDetailView: View {
    let issue: MyIssue

    @State private var commentText = ""
    @State private var comments: [IssueComment] = []
    @State private var isLoadingComments = false
    @State private var isSubmitting = false
    @State private var commentError: String?

    @EnvironmentObject private var session: SessionStore

    private let service = GitHubService()

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(
                            systemName: issue.state == "open"
                                ? "circle"
                                : "checkmark.circle.fill"
                        )
                        .foregroundStyle(
                            issue.state == "open"
                                ? .green
                                : .purple
                        )

                        Text(issue.state.capitalized)
                            .font(.subheadline.bold())
                            .foregroundStyle(
                                issue.state == "open"
                                    ? .green
                                    : .purple
                            )

                        Spacer()

                        Text(String(issue.createdAt.prefix(10)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(issue.title)
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Divider()
                        .background(Color.white.opacity(0.2))

                    if let body = issue.body, !body.isEmpty {
                        MarkdownText(
                            body,
                            color: .white.opacity(0.8)
                        )
                    } else {
                        Text("No description provided.")
                            .italic()
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    commentsSection
                }
                .padding()
            }

            commentInput
        }
        .background(
            Color(
                red: 0.05,
                green: 0.09,
                blue: 0.12
            )
            .ignoresSafeArea()
        )
        .navigationTitle(
            "\(issue.repositoryName) #\(issue.number)"
        )
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadComments()
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Replies")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                Text("\(comments.count)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            if isLoadingComments {
                HStack {
                    Spacer()

                    ProgressView()
                        .tint(.cyan)

                    Spacer()
                }
                .padding(.vertical, 20)
            } else if let commentError {
                VStack(spacing: 8) {
                    Text(commentError)
                        .font(.subheadline)
                        .foregroundStyle(.red.opacity(0.9))
                        .multilineTextAlignment(.center)

                    Button("Retry") {
                        Task {
                            await loadComments()
                        }
                    }
                    .foregroundStyle(.cyan)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if comments.isEmpty {
                Text("No comments yet.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.vertical, 12)
            } else {
                ForEach(comments) { comment in
                    IssueCommentView(comment: comment)
                }
            }
        }
    }

    private var commentInput: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.2))

            HStack(alignment: .bottom, spacing: 12) {
                TextField(
                    "Leave a comment...",
                    text: $commentText,
                    axis: .vertical
                )
                .lineLimit(1 ... 5)
                .padding(10)
                .background(Color.white.opacity(0.05))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
                .foregroundStyle(.white)

                Button {
                    Task {
                        await submitComment()
                    }
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .tint(.cyan)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(
                                commentText
                                    .trimmingCharacters(
                                        in: .whitespacesAndNewlines
                                    )
                                    .isEmpty
                                    ? .gray
                                    : .cyan
                            )
                    }
                }
                .disabled(
                    commentText
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                        .isEmpty || isSubmitting
                )
                .padding(.bottom, 8)
            }
            .padding()
            .background(
                Color(
                    red: 0.05,
                    green: 0.09,
                    blue: 0.12
                )
            )
        }
    }

    @MainActor
    private func loadComments() async {
        let parts = issue.repositoryName.split(
            separator: "/"
        )

        guard parts.count >= 2 else {
            commentError = "Invalid repository name."
            return
        }

        let owner = String(parts[0])
        let repo = String(parts[1])

        isLoadingComments = true
        commentError = nil

        let fetchedComments = await service.fetchIssueComments(
            owner: owner,
            repo: repo,
            issueNumber: issue.number,
            token: session.savedAccessKey
        )

        comments = fetchedComments
        isLoadingComments = false
    }

    @MainActor
    private func submitComment() async {
        let text = commentText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !text.isEmpty else {
            return
        }

        let parts = issue.repositoryName.split(
            separator: "/"
        )

        guard parts.count >= 2 else {
            return
        }

        let owner = String(parts[0])
        let repo = String(parts[1])

        isSubmitting = true

        let success = await service.postIssueComment(
            owner: owner,
            repo: repo,
            issueNumber: issue.number,
            body: text,
            token: session.savedAccessKey
        )

        isSubmitting = false

        guard success else {
            commentError = "Failed to post comment."
            return
        }

        commentText = ""

        await loadComments()
    }
}

private struct IssueCommentView: View {
    let comment: IssueComment

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                AsyncImage(url: URL(string: comment.user.avatarURL ?? "")) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()

                    case .failure, .empty:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.cyan)

                    @unknown default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.cyan)
                    }
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())

                Text(comment.user.login)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)

                Spacer()

                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }

            MarkdownText(
                comment.body,
                color: .white.opacity(0.8)
            )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(14)
        .background(
            Color.white.opacity(0.04)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .stroke(
                Color.white.opacity(0.06),
                lineWidth: 1
            )
        )
    }

    private var formattedDate: String {
        String(comment.createdAt.prefix(10))
    }
}
