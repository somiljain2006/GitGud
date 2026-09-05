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
                    .foregroundStyle(
                        isSelected
                            ? Color.cyan
                            : Color.white.opacity(0.65)
                    )
                    .symbolRenderingMode(.hierarchical)

                if showDot {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 7, height: 7)
                        .offset(x: 7, y: -6)
                }
            }

            Text(title)
                .font(
                    .system(
                        size: 11,
                        weight: .semibold,
                        design: .rounded
                    )
                )
                .foregroundStyle(
                    isSelected
                        ? Color.cyan
                        : Color.white.opacity(0.65)
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
