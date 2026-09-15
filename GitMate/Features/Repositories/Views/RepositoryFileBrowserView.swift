//
//  RepositoryFileBrowserView.swift
//  GitMate
//
//  Created by somil jain on 13/09/26.
//

import SwiftUI

struct RepositoryFileBrowserView: View {
    let owner: String
    let repo: String
    let branch: String
    let path: String
    let canCommit: Bool

    @EnvironmentObject var sessionStore: SessionStore
    @State private var items: [GitHubDirectoryItem] = []
    @State private var isLoading = true
    @State private var error: String?

    private let service = GitHubService()

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.09, blue: 0.12).ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .tint(.cyan)
            } else if let error = error {
                Text(error)
                    .foregroundStyle(.red)
            } else if items.isEmpty {
                Text("This folder is empty.")
                    .foregroundStyle(.secondary)
            } else {
                List {
                    ForEach(sortedItems) { item in
                        if item.type == "dir" {
                            NavigationLink(destination: RepositoryFileBrowserView(owner: owner, repo: repo, branch: branch, path: item.path, canCommit: canCommit)) {
                                fileRow(item: item)
                            }
                        } else {
                            NavigationLink(destination: PullRequestFileEditorView(headOwner: owner, headRepo: repo, headBranch: branch, filePath: item.path, token: sessionStore.savedAccessKey, isPullRequest: false, canCommit: canCommit)) {
                                fileRow(item: item)
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(path.isEmpty ? repo : path.components(separatedBy: "/").last ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadContents()
        }
    }

    private var sortedItems: [GitHubDirectoryItem] {
        items.sorted {
            if $0.type == $1.type {
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            return $0.type == "dir"
        }
    }

    private func fileRow(item: GitHubDirectoryItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.type == "dir" ? "folder.fill" : "doc.text")
                .foregroundStyle(item.type == "dir" ? .blue : .gray)

            Text(item.name)
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func loadContents() async {
        isLoading = true
        error = nil
        if let fetched = await service.fetchDirectoryContents(owner: owner, repo: repo, path: path, branch: branch, token: sessionStore.savedAccessKey) {
            items = fetched
        } else {
            error = "Failed to load directory contents."
        }
        isLoading = false
    }
}
