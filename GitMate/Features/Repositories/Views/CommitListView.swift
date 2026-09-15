//
//  CommitListView.swift
//  GitMate
//
//  Created by somil jain on 13/09/26.
//

import SwiftUI

struct CommitListView: View {
    let owner: String
    let repo: String
    let branch: String

    @EnvironmentObject var sessionStore: SessionStore
    @State private var commits: [PullRequestCommit] = []
    @State private var isLoading = true

    private let service = GitHubService()

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.09, blue: 0.12).ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .tint(.cyan)
            } else if commits.isEmpty {
                Text("No commits found.")
                    .foregroundStyle(.secondary)
            } else {
                List(commits) { commit in
                    NavigationLink(destination: CommitDetailView(owner: owner, repo: repo, sha: commit.sha)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(commit.commit.message.components(separatedBy: "\n").first ?? "")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .lineLimit(1)

                            HStack {
                                if let avatar = commit.author?.avatarUrl {
                                    AsyncImage(url: URL(string: avatar)) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Circle().fill(Color.gray.opacity(0.3))
                                    }
                                    .frame(width: 20, height: 20)
                                    .clipShape(Circle())
                                }
                                Text(commit.author?.login ?? "Unknown")
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text(String(commit.sha.prefix(7)))
                                    .font(.caption)
                                    .foregroundStyle(.cyan)
                                    .padding(4)
                                    .background(Color.cyan.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Commits")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            commits = await service.fetchRepositoryCommits(owner: owner, repo: repo, branch: branch, token: sessionStore.savedAccessKey)
            isLoading = false
        }
    }
}
