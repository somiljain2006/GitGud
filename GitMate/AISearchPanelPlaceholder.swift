//
//  AISearchPanelPlaceholder.swift
//  GitMate
//
//  Created by somil jain on 12/09/26.
//

import SwiftUI

struct AISearchPanelPlaceholder: View {
    let onClose: () -> Void

    @State private var searchText = ""
    @State private var showingSettings = false

    @State private var messages: [AIChatMessage] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation(
                    .spring(
                        response: 0.4,
                        dampingFraction: 0.85
                    )
                ) {
                    onClose()
                }
            } label: {
                SiriOrbView(isActive: isLoading)
                    .frame(width: 64, height: 64)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close AI Search")

            if !messages.isEmpty {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(messages) { message in
                            messageBubble(message)
                        }

                        if isLoading {
                            HStack {
                                ProgressView()
                                    .tint(.cyan)

                                Text("GitMate is thinking...")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)

                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(maxHeight: 220)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.cyan)

                TextField(
                    "Ask GitMate anything...",
                    text: $searchText
                )
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .submitLabel(.search)
                .onSubmit {
                    sendMessage()
                }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }

                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("AI Search Settings")
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background {
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .fill(Color.white.opacity(0.08))
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .stroke(
                    Color.white.opacity(0.14),
                    lineWidth: 1
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(
                    cornerRadius: 22,
                    style: .continuous
                )
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.3),
                            .cyan.opacity(0.2),
                            .white.opacity(0.08),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            }
        }
        .shadow(
            color: .black.opacity(0.35),
            radius: 18,
            x: 0,
            y: 8
        )
        .sheet(isPresented: $showingSettings) {
            AISettingsView()
        }
    }

    private func messageBubble(
        _ message: AIChatMessage
    ) -> some View {
        HStack {
            if message.role == .assistant {
                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text("GitMate")
                        .font(.caption)
                        .foregroundStyle(.cyan)

                    Text(message.content)
                        .foregroundStyle(.white)
                        .textSelection(.enabled)
                }
                .padding(12)
                .background {
                    RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
                    .fill(Color.white.opacity(0.08))
                }

                Spacer(minLength: 30)
            } else {
                Spacer(minLength: 30)

                Text(message.content)
                    .foregroundStyle(.white)
                    .textSelection(.enabled)
                    .padding(12)
                    .background {
                        RoundedRectangle(
                            cornerRadius: 14,
                            style: .continuous
                        )
                        .fill(Color.cyan.opacity(0.18))
                    }
            }
        }
    }

    private func sendMessage() {
        let trimmedMessage = searchText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmedMessage.isEmpty,
              !isLoading
        else {
            return
        }

        errorMessage = nil

        let previousConversation = messages

        messages.append(
            AIChatMessage(
                role: .user,
                content: trimmedMessage
            )
        )

        searchText = ""
        isLoading = true

        Task {
            do {
                let response = try await AIService.shared.sendMessage(
                    trimmedMessage,
                    conversation: previousConversation
                )

                await MainActor.run {
                    messages.append(
                        AIChatMessage(
                            role: .assistant,
                            content: response
                        )
                    )

                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        VStack {
            Spacer()

            AISearchPanelPlaceholder {
                print("Close AI Search")
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 100)
        }
    }
    .preferredColorScheme(.dark)
}
