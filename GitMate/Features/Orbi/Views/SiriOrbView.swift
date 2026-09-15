//  SiriOrbView.swift
//  GitMate
//
//  Created by somil jain on 11/09/26.
//

import SwiftUI

struct SiriOrbView: View {
    let isActive: Bool
    @State private var animate = false
    @State private var pulse = false

    private var size: CGFloat {
        isActive ? 70 : 62
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            .pink,
                            .purple,
                            .blue,
                            .cyan,
                            .green,
                            .pink,
                        ],
                        center: .center,
                        startAngle: .degrees(animate ? 0 : 360),
                        endAngle: .degrees(animate ? 360 : 720)
                    )
                )
                .frame(width: size * 1.15, height: size * 1.15)
                .blur(radius: 12)
                .opacity(isActive ? 0.75 : 0.4)
                .scaleEffect(pulse ? 1.1 : 0.95)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.purple.opacity(0.3), .indigo.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.5
                        )
                    )

                ribbon(
                    colors: [.pink, .purple, .white.opacity(0.2)],
                    angle: animate ? -22 : 22,
                    offset: CGPoint(x: animate ? -3 : 3, y: -3),
                    ribbonSize: CGSize(width: size * 0.9, height: size * 0.38)
                )

                ribbon(
                    colors: [.cyan, .blue, .purple.opacity(0.25)],
                    angle: animate ? 24 : -18,
                    offset: CGPoint(x: animate ? 3 : -3, y: 3),
                    ribbonSize: CGSize(width: size * 0.85, height: size * 0.38)
                )

                ribbon(
                    colors: [.green, .cyan, .blue.opacity(0.2)],
                    angle: animate ? 52 : 32,
                    offset: CGPoint(x: -2, y: animate ? -3 : 3),
                    ribbonSize: CGSize(width: size * 0.72, height: size * 0.32)
                )

                ribbon(
                    colors: [.purple, .pink, .white.opacity(0.18)],
                    angle: animate ? -52 : -32,
                    offset: CGPoint(x: 2, y: animate ? 3 : -3),
                    ribbonSize: CGSize(width: size * 0.7, height: size * 0.3)
                )

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .white.opacity(0.95),
                                .white.opacity(0.7),
                                .cyan.opacity(0.25),
                                .clear,
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.35
                        )
                    )
                    .frame(width: size * 0.5, height: size * 0.5)
                    .blur(radius: 2)

                Circle()
                    .fill(.white.opacity(0.9))
                    .frame(
                        width: isActive ? 5 : 4,
                        height: isActive ? 5 : 4
                    )
                    .blur(radius: 1)
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                .white.opacity(0.6),
                                .pink.opacity(0.25),
                                .white.opacity(0.15),
                                .cyan.opacity(0.25),
                                .white.opacity(0.4),
                                .green.opacity(0.2),
                                .purple.opacity(0.2),
                                .white.opacity(0.6),
                            ],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        lineWidth: 1.0
                    )
                    .rotationEffect(.degrees(animate ? 180 : -90))
                    .opacity(0.6)
                    .blendMode(.plusLighter)
            )
        }
        .frame(width: 100, height: 100)
        .animation(
            .easeInOut(duration: 2.2)
                .repeatForever(autoreverses: true),
            value: animate
        )
        .animation(
            .easeInOut(duration: 1.8)
                .repeatForever(autoreverses: true),
            value: pulse
        )
        .onAppear {
            animate = true
            pulse = true
        }
    }

    private func ribbon(
        colors: [Color],
        angle: Double,
        offset: CGPoint,
        ribbonSize: CGSize
    ) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: ribbonSize.width, height: ribbonSize.height)
            .blur(radius: isActive ? 2.0 : 1.5)
            .opacity(isActive ? 0.95 : 0.7)
            .rotationEffect(.degrees(angle))
            .offset(x: offset.x, y: offset.y)
            .blendMode(.screen)
    }
}
