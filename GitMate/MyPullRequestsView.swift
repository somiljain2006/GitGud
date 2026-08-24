//
//  MyPullRequestsView.swift
//  GitMate
//
//  Created by somil jain on 23/08/26.
//

import SwiftUI

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
               !body.isEmpty
            {
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
