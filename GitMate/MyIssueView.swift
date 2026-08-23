//
//  MyIssueView.swift
//  GitMate
//
//  Created by somil jain on 23/08/26.
//

import Foundation
import SwiftUI

struct MyIssuesView: View {
    let issues: [MyIssue]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if issues.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 40))
                                .foregroundStyle(.green)

                            Text("No issues opened by you")
                                .font(.headline)
                                .foregroundStyle(.white)

                            Text("Issues you create will appear here.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    } else {
                        ForEach(issues) { issue in
                            IssueCard(issue: issue) {
                                if let url = URL(string: issue.htmlURL) {
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
            .navigationTitle("My Issues")
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

struct IssueCard: View {
    let issue: MyIssue
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
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

                    Text("#\(issue.number)")
                        .font(
                            .system(
                                size: 13,
                                weight: .medium,
                                design: .monospaced
                            )
                        )
                        .foregroundStyle(.white.opacity(0.5))

                    Spacer()

                    Text(issue.repositoryName)
                        .font(
                            .system(
                                size: 12,
                                design: .monospaced
                            )
                        )
                        .foregroundStyle(.white.opacity(0.5))
                }

                Text(issue.title)
                    .font(
                        .system(
                            size: 17,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)

                if let body = issue.body,
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
        .buttonStyle(.plain)
    }
}

struct MyIssue: Identifiable, Codable {
    let id: Int
    let number: Int
    let title: String
    let state: String
    let body: String?
    let htmlURL: String
    let repositoryName: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case number
        case title
        case state
        case body
        case htmlURL = "html_url"
        case repositoryName
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
