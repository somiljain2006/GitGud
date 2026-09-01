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

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if issues.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(issues) { issue in
                            NavigationLink(destination: IssueDetailView(issue: issue)) {
                                IssueCard(issue: issue)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(red: 0.05, green: 0.09, blue: 0.12).ignoresSafeArea())
            .navigationTitle("My Issues")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var emptyStateView: some View {
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
    }
}

struct IssueCard: View {
    let issue: MyIssue

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: issue.state == "open" ? "circle" : "checkmark.circle.fill")
                    .foregroundStyle(issue.state == "open" ? .green : .purple)

                Text("#\(issue.number)")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Text(issue.repositoryName)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Text(issue.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)

            if let body = issue.body, !body.isEmpty {
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
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
