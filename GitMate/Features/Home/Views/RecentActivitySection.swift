//
//  RecentActivitySection.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import SwiftUI

struct RecentActivitySection: View {
    let activities: [ActivityItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Activity")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 2)
                        .padding(.leading, 31)
                        .padding(.vertical, 22)

                    VStack(spacing: 18) {
                        ForEach(activities) { activity in
                            ActivityRow(activity: activity)
                        }
                    }
                    .padding(16)
                }
                .background(GlassCard(cornerRadius: 18))
            }
        }
    }
}
