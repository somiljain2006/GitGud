//
//  DockItem.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import SwiftUI

struct DockItem: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let showDot: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.cyan : Color.white.opacity(0.65))
                    .symbolRenderingMode(.hierarchical)

                if showDot {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 7, height: 7)
                        .shadow(color: .cyan.opacity(0.9), radius: 6)
                        .offset(x: 7, y: -6)
                }
            }
            
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? Color.cyan : Color.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.cyan.opacity(0.14))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.35),
                                        Color.white.opacity(0.08),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .cyan.opacity(0.25), radius: 10, y: 4)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isSelected)
    }
}
