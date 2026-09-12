//
//  PRFileAIChatPanel.swift
//  GitMate
//
//  Created by somil jain on 12/09/26.
//

import SwiftUI

struct PRFileAIChatPanel: View {
    let filePath: String
    let currentCode: String
    let onApplyCode: (String) -> Void
    let onClose: () -> Void

    @State private var inputText = ""
    @State private var messages: [AIChatMessage] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastExtractedCode: String?

    private var filename: String {
        filePath.components(separatedBy: "/").last ?? filePath
    }

    private var systemPrompt: String {
        """
        You are Orbi, an expert code assistant embedded inside a GitHub PR file editor.
        The user is viewing and editing the following file: \(filePath)

        Here is the current file content:
        ```
        \(currentCode)
        ```

        When the user asks you to make changes, always return the COMPLETE revised file content \
        inside a single fenced code block. Do not truncate or omit any unchanged lines — \
        return the full file so it can be applied directly. Explain what you changed briefly \
        before the code block.
        """
    }

    var body: some View {
        VStack(spacing: 0) {
            panelHeader
            Divider().background(Color.white.opacity(0.1))
            chatScrollView
            if let lastExtractedCode {
                applyChangesBar(code: lastExtractedCode)
            }
            Divider().background(Color.white.opacity(0.1))
            inputBar
        }
        .background(Color(red: 0.05, green: 0.09, blue: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 8)
    }

    private var panelHeader: some View {
        HStack(spacing: 10) {
            Spacer()

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close AI Panel")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var chatScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(messages) { message in
                            messageBubble(message)
                                .id(message.id.uuidString)
                        }

                        if isLoading {
                            typingIndicator
                                .id("typing")
                        }
                    }
                }
                .padding(14)
            }
            .onChange(of: messages.count) {
                withAnimation {
                    proxy.scrollTo(
                        messages.last?.id.uuidString ?? "typing",
                        anchor: .bottom
                    )
                }
            }
            .onChange(of: isLoading) {
                if isLoading {
                    withAnimation {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
        .frame(maxHeight: 340)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 32))
                .foregroundStyle(.cyan.opacity(0.7))

            Text("Ask Orbi about this file")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))

            Text("e.g. \"Add error handling to the fetchData function\" or \"Refactor this to use async/await\"")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 8)
    }

    private var typingIndicator: some View {
        HStack {
            ProgressView()
                .tint(.cyan)
                .scaleEffect(0.8)

            Text("Orbi is thinking…")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))

            Spacer()
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }

            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.cyan)

                TextField(
                    "Ask about this file…",
                    text: $inputText,
                    axis: .vertical
                )
                .lineLimit(1 ... 4)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .submitLabel(.send)
                .onSubmit { sendMessage() }

                if !inputText.isEmpty {
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title3)
                            .foregroundStyle(isLoading ? .gray : .cyan)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }

    private func applyChangesBar(code: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)

            Text("AI suggested a code change")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)

            Spacer()

            Button {
                onApplyCode(code)
                lastExtractedCode = nil
            } label: {
                Text("Apply")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.green.opacity(0.1))
    }

    @ViewBuilder
    private func messageBubble(_ message: AIChatMessage) -> some View {
        if message.role == .user {
            HStack {
                Spacer(minLength: 40)
                Text(message.content)
                    .foregroundStyle(.white)
                    .textSelection(.enabled)
                    .padding(12)
                    .background(Color.cyan.opacity(0.18))
                    .clipShape(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
            }
        } else {
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Orbi")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.cyan)

                    Text(message.content)
                        .foregroundStyle(.white.opacity(0.9))
                        .textSelection(.enabled)
                        .font(.system(size: 14))
                }
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                )

                Spacer(minLength: 40)
            }
        }
    }

    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isLoading else { return }

        errorMessage = nil
        lastExtractedCode = nil

        let previousConversation = messages
        messages.append(AIChatMessage(role: .user, content: trimmed))
        inputText = ""
        isLoading = true

        Task {
            do {
                let response = try await AIService.shared.sendMessage(
                    trimmed,
                    systemPrompt: systemPrompt,
                    conversation: previousConversation
                )

                await MainActor.run {
                    messages.append(
                        AIChatMessage(role: .assistant, content: response)
                    )
                    lastExtractedCode = extractCodeBlock(from: response)
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

    private func extractCodeBlock(from text: String) -> String? {
        let pattern = #"```[^\n]*\n([\s\S]*?)```"#
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(
                in: text,
                range: NSRange(text.startIndex..., in: text)
            ),
            let range = Range(match.range(at: 1), in: text)
        else {
            return nil
        }

        let extracted = String(text[range])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return extracted.isEmpty ? nil : extracted
    }
}
