//
//  PinnedRepositoriesSection.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import SwiftUI

struct PinnedRepositoriesSection: View {
    let repos: [PinnedRepo]
    let onViewAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Pinned Repositories")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button("VIEW ALL") {
                    onViewAll()
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color.cyan)
            }
            
            VStack(spacing: 12) {
                ForEach(repos) { repo in
                    PinnedRepoCard(repo: repo)
                }
            }
        }
    }
}
