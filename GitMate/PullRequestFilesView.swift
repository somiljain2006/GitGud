//
//  PullRequestFilesView.swift
//  GitMate
//
//  Created by somil jain on 25/08/26.
//

import SwiftUI

struct PullRequestFilesView: View {
    let files: [PullRequestFile]
    let pr: PullRequestDetail?
    let token: String?

    var onCommitSuccess: (() -> Void)?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if files.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc")
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.4))

                        Text("No files changed.")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    ForEach(files) { file in
                        NavigationLink {
                            fileDestination(for: file)
                        } label: {
                            fileLabel(for: file)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .background(
            Color(red: 0.05, green: 0.09, blue: 0.12)
                .ignoresSafeArea()
        )
        .navigationTitle("Files Changed")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func fileDestination(for file: PullRequestFile) -> some View {
        if let headRepo = pr?.head.repo,
           let headRef = pr?.head.ref
        {
            PullRequestFileEditorView(
                headOwner: headRepo.owner.login,
                headRepo: headRepo.name,
                headBranch: headRef,
                filePath: file.filename,
                token: token,
                onCommitSuccess: onCommitSuccess
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

    private func fileLabel(for file: PullRequestFile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: fileIcon(for: file.filename))
                    .foregroundStyle(.cyan)

                Text(file.filename)
                    .font(
                        .system(
                            size: 14,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(.cyan)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }

            HStack(spacing: 10) {
                Text("+\(file.additions)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)

                Text("-\(file.deletions)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.red)

                Spacer()

                if let patch = file.patch, !patch.isEmpty {
                    Text("View diff")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
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

    private func fileIcon(for path: String) -> String {
        let extensionName = path
            .split(separator: ".")
            .last
            .map { String($0).lowercased() }

        switch extensionName {
        case "swift":
            return "swift"
        case "java":
            return "cup.and.saucer"
        case "js", "jsx", "ts", "tsx":
            return "curlybraces"
        case "json":
            return "curlybraces.square"
        case "md":
            return "doc.richtext"
        case "png", "jpg", "jpeg", "gif":
            return "photo"
        default:
            return "doc.text"
        }
    }
}
