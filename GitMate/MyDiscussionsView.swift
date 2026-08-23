//
//  MyDiscussionsView.swift
//  GitMate
//
//  Created by somil jain on 23/08/26.
//

import SwiftUI

struct MyDiscussionsView: View {
    let discussions: [MyDiscussion]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if discussions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 40))
                                .foregroundStyle(.green)

                            Text("No discussions started by you")
                                .font(.headline)
                                .foregroundStyle(.white)

                            Text("Discussions you create will appear here.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    } else {
                        ForEach(discussions) { discussion in
                            DiscussionCard(discussion: discussion) {
                                if let url = URL(string: discussion.url) {
                                    openURL(url)
                                }
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
            .navigationTitle("My Discussions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .navigationBarTrailing
                ) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct DiscussionCard: View {
    let discussion: MyDiscussion
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .foregroundStyle(.blue)

                    Spacer()

                    Text(discussion.repositoryName)
                        .font(
                            .system(
                                size: 12,
                                design: .monospaced
                            )
                        )
                        .foregroundStyle(.white.opacity(0.5))
                }

                Text(discussion.title)
                    .font(
                        .system(
                            size: 17,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)

                if let body = discussion.body,
                   !body.isEmpty {
                    Text(body)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
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
        .buttonStyle(.plain)
    }
}
