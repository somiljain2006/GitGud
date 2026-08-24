//
//  PRView.swift
//  GitMate
//
//  Created by somil jain on 25/08/26.
//

import SwiftUI

struct PRDiffView: View {
    let patch: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(
                Array(patch.components(separatedBy: "\n").enumerated()),
                id: \.offset
            ) { _, line in
                PRDiffLineView(line: line)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PRDiffLineView: View {
    let line: String

    var body: some View {
        let isAdded = line.hasPrefix("+") && !line.hasPrefix("+++")
        let isRemoved = line.hasPrefix("-") && !line.hasPrefix("---")
        let isHeader = line.hasPrefix("@@")

        return Text(line)
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(
                isAdded
                    ? .green
                    : isRemoved
                    ? .red
                    : isHeader
                    ? .cyan
                    : .white.opacity(0.7)
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 2)
            .background(
                isAdded
                    ? Color.green.opacity(0.10)
                    : isRemoved
                    ? Color.red.opacity(0.10)
                    : Color.clear
            )
    }
}

struct PRReviewCommentHeaderView: View {
    let comment: PullRequestReviewComment

    var body: some View {
        HStack(spacing: 8) {
            AsyncImage(url: URL(string: comment.user.avatarUrl)) { image in
                image.resizable()
            } placeholder: {
                Circle().fill(.gray.opacity(0.3))
            }
            .frame(width: 28, height: 28)
            .clipShape(Circle())

            Text(comment.user.login)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            Spacer()

            Text(RelativeDateFormatter.relativeString(from: comment.createdAt))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}

struct PRReviewReplyBlockView: View {
    let reply: PullRequestReviewComment

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider().background(.white.opacity(0.1))

            PRReviewCommentHeaderView(comment: reply)

            MarkdownText(reply.body, color: .white.opacity(0.85))
                .font(.body)
        }
        .padding(12)
    }
}

struct PRCommitRowView: View {
    let commit: PullRequestCommit

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(commit.commit.message.components(separatedBy: "\n").first ?? "")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)

            Text(String(commit.sha.prefix(7)))
                .font(.caption.monospaced())
                .foregroundStyle(.cyan)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
