//
//  MarkdownText.swift
//  GitMate
//
//  Created by somil jain on 24/08/26.
//

import SwiftUI

struct MarkdownText: View {
    let markdown: String
    let color: Color

    init(
        _ markdown: String,
        color: Color = .white
    ) {
        self.markdown = markdown
        self.color = color
    }

    private var normalizedLines: [String] {
        let normalized = markdown
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\r\n", with: "\n")
        return normalized.components(separatedBy: "\n")
    }

    private func attributed(for line: String) -> AttributedString {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let leadingSpaces = line.prefix(while: { $0.isWhitespace })

        var content = line

        if let taskMatch = trimmed.range(of: #"^([-*+])\s+\[([ xX])\]\s+"#, options: .regularExpression) {
            let isChecked = trimmed.lowercased().contains("[x]")
            let rest = trimmed[taskMatch.upperBound...]
            _ = isChecked ? "☑" : "☐"
            if isChecked {
                content = "\(leadingSpaces)☑ ~~\(rest)~~"
            } else {
                content = "\(leadingSpaces)☐ \(rest)"
            }
        } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
            content = "\(leadingSpaces)• \(trimmed.dropFirst(2))"
        }

        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .full
        options.failurePolicy = .returnPartiallyParsedIfPossible

        if let attributed = try? AttributedString(markdown: content, options: options) {
            return attributed
        }
        return AttributedString(content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(normalizedLines.enumerated()), id: \.offset) { _, line in
                if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    Spacer().frame(height: 8)
                } else {
                    Text(attributed(for: line))
                        .foregroundStyle(color)
                        .textSelection(.enabled)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
