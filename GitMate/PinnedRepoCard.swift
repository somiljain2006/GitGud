//
//  PinnedRepoCard.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import SwiftUI

struct PinnedRepoCard: View {
    let repo: PinnedRepo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                HStack(spacing: 8) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.cyan)
                    
                    Text(repo.name)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                Text(repo.isPublic ? "Public" : "Private")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
            }
            
            Text(repo.description)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(2)
            
            HStack(spacing: 14) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(repo.color)
                        .frame(width: 10, height: 10)
                    Text(repo.language)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.72))
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "star")
                        .font(.system(size: 12, weight: .semibold))
                    Text(repo.stars)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                }
                .foregroundStyle(.white.opacity(0.72))
                
                Spacer()
                
                Text("Updated recently")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.42))
            }
        }
        .padding(16)
        .background(GlassCard(cornerRadius: 18))
    }
}
