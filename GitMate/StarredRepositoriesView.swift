//
//  StarredRepositoriesView.swift
//  GitMate
//
//  Created by somil jain on 23/08/26.
//

import SwiftUI

struct StarredRepositoriesView: View {
    let repositories: [StarredRepository]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if repositories.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "star")
                                .font(.system(size: 40))
                                .foregroundStyle(.yellow)

                            Text("No starred repositories")
                                .font(.headline)
                                .foregroundStyle(.white)

                            Text("Repositories you star will appear here.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    } else {
                        ForEach(repositories) { repository in
                            StarredRepositoryCard(
                                repository: repository
                            ) {
                                if let url = URL(string: repository.url) {
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
            .navigationTitle("Starred Repositories")
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

struct StarredRepositoryCard: View {
    let repository: StarredRepository
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)

                    Text(repository.fullName)
                        .font(
                            .system(
                                size: 13,
                                weight: .medium,
                                design: .monospaced
                            )
                        )
                        .foregroundStyle(.white.opacity(0.6))

                    Spacer()
                }

                Text(repository.name)
                    .font(
                        .system(
                            size: 18,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.white)

                if let description = repository.description,
                   !description.isEmpty {
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                HStack(spacing: 16) {
                    Label(
                        "\(repository.stars)",
                        systemImage: "star.fill"
                    )

                    if let language = repository.language {
                        Label(
                            language,
                            systemImage: "circle.fill"
                        )
                    }
                }
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.5))
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
