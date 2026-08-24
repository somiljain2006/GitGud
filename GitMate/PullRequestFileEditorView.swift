//
//  PullRequestFileEditorView.swift
//  GitMate
//
//  Created by somil jain on 25/08/26.
//

import SwiftUI

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
        MultiLanguageCodeEditor(text: $editedText, filePath: filePath)
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

        let req = FileUpdateRequest(
            owner: headOwner,
            repo: headRepo,
            path: filePath,
            branch: headBranch,
            sha: sha,
            content: editedText,
            commitMessage: commitMessage,
            token: token
        )
        let result = await service.updateFile(req: req)

        switch result {
        case .success:
            showCommitSheet = false
            onCommitSuccess?()
            dismiss()
        case let .failure(err):
            commitError = err.localizedDescription
        }

        isCommitting = false
    }

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
