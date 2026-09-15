//
//  CommitDetailView.swift
//  GitMate
//
//  Created by somil jain on 13/09/26.
//

import SwiftUI

struct CommitDetailView: View {
    let owner: String
    let repo: String
    let sha: String

    @EnvironmentObject var sessionStore: SessionStore
    @State private var commitDetail: GitHubCommitDetail?
    @State private var isLoading = true

    private let service = GitHubService()

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.09, blue: 0.12).ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .tint(.cyan)
            } else if let detail = commitDetail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(detail.commit.message)
                                .font(.title3.bold())
                                .foregroundStyle(.white)

                            HStack {
                                if let avatar = detail.author?.avatarUrl {
                                    AsyncImage(url: URL(string: avatar)) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Circle().fill(Color.gray.opacity(0.3))
                                    }
                                    .frame(width: 24, height: 24)
                                    .clipShape(Circle())
                                }
                                Text(detail.author?.login ?? detail.commit.author?.name ?? "Unknown")
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)

                                Spacer()

                                Text(String(sha.prefix(7)))
                                    .font(.system(.subheadline, design: .monospaced))
                                    .foregroundStyle(.cyan)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.cyan.opacity(0.1))
                                    .clipShape(Capsule())
                            }

                            if let stats = detail.stats {
                                HStack(spacing: 16) {
                                    Label("\(stats.total) changed files", systemImage: "doc.on.doc")
                                    Label("\(stats.additions) additions", systemImage: "plus.square").foregroundStyle(.green)
                                    Label("\(stats.deletions) deletions", systemImage: "minus.square").foregroundStyle(.red)
                                }
                                .font(.caption)
                                .foregroundStyle(.gray)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)

                        if let files = detail.files {
                            LazyVStack(spacing: 16) {
                                ForEach(files) { file in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(file.filename)
                                                .font(.headline)
                                                .foregroundStyle(.white)
                                            Spacer()
                                            Text("+\(file.additions) -\(file.deletions)")
                                                .font(.caption)
                                                .foregroundStyle(.gray)
                                        }

                                        if let patch = file.patch {
                                            ScrollView(.horizontal) {
                                                Text(patch)
                                                    .font(.system(.caption, design: .monospaced))
                                                    .foregroundStyle(.white.opacity(0.8))
                                            }
                                            .padding()
                                            .background(Color.black.opacity(0.3))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        } else {
                                            Text("Large diffs are not rendered by default.")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            } else {
                Text("Failed to load commit details.")
                    .foregroundStyle(.red)
            }
        }
        .navigationTitle("Commit")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            commitDetail = await service.fetchCommitDetail(owner: owner, repo: repo, sha: sha, token: sessionStore.savedAccessKey)
            isLoading = false
        }
    }
}
