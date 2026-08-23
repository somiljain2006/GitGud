//
//  ActivityRow.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import SwiftUI

struct ActivityRow: View {
    let activity: ActivityItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.14), lineWidth: 1)
                    )

                Image(systemName: activity.systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(activity.tint)
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text(activity.subtitle)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.70))

                Text(activity.timestamp)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.top, 2)
            }

            Spacer()
        }
        .padding(.leading, 2)
    }
}
