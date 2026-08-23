//
//  QuickActionCard.swift
//  GitGud
//
//  Created by somil jain on 13/07/26.
//

import SwiftUI

struct QuickActionCard: View {
    let action: QuickAction
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                GlassCard(cornerRadius: 20)

                LinearGradient(
                    colors: [
                        action.tint.opacity(0.18),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 20,
                        style: .continuous
                    )
                )

                VStack(alignment: .leading) {
                    HStack(alignment: .top) {
                        Text(action.subtitle)
                            .font(
                                .system(
                                    size: 13,
                                    weight: .medium,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(.white.opacity(0.7))

                        Spacer()

                        Image(action.imageName)
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(action.tint)
                            .scaledToFit()
                            .frame(
                                width: 26,
                                height: 26
                            )
                    }

                    Spacer()

                    Text(action.title)
                        .font(
                            .system(
                                size: 22,
                                weight: .semibold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                }
                .padding(14)
            }
            .frame(height: 132)
        }
        .buttonStyle(ScaledButtonStyle())
    }
}
