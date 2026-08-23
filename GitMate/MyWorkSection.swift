//
//  MyWorkSection.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import SwiftUI

struct MyWorkSection: View {
    let items: [WorkItem]
    @EnvironmentObject private var session: SessionStore
    @State private var selectedPR: PullRequestReference?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("My Work")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            VStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { index in
                    let item = items[index]

                    if item.type == .pullRequest, let number = item.pullRequestNumber, let owner = item.owner, let repo = item.repo {
                        Button {
                            selectedPR = PullRequestReference(owner: owner, repository: repo, number: number)
                        } label: {
                            WorkCard(item: item)
                        }
                        .buttonStyle(.plain)
                    } else {
                        WorkCard(item: item)
                    }

                    if index != items.count - 1 {
                        Divider()
                            .overlay(Color.white.opacity(0.08))
                            .padding(.leading, 62)
                    }
                }
            }
            .padding(.vertical, 4)
            .background(GlassCard(cornerRadius: 20))
        }
        .sheet(item: $selectedPR) { ref in
            NavigationStack {
                PullRequestDetailView(reference: ref, token: session.savedAccessKey)
            }
            .preferredColorScheme(.dark)
        }
    }
}
