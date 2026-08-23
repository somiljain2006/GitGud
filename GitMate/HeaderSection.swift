//
//  HeaderSection.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import SwiftUI

struct HeaderSection: View {
    let avatarURL: String?

    var body: some View {
        HStack {
            AsyncImage(url: URL(string: avatarURL ?? "")) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundStyle(.white.opacity(0.92))
                case .empty:
                    ProgressView()
                        .tint(.cyan)
                @unknown default:
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundStyle(.white.opacity(0.92))
                }
            }
            .frame(width: 42, height: 42)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            )
            .background(
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 42, height: 42)
            )

            Spacer()

            Button(action: {}, label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.cyan)
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.08), in: Circle())
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.12), lineWidth: 1)
                    )
            })
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }
}
