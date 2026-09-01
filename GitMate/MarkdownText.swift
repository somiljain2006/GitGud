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

    private var normalizedMarkdown: String {
        var value = markdown
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\r\n", with: "\n")

        value = value.replacingOccurrences(
            of: #"<!--[\s\S]*?-->"#,
            with: "",
            options: .regularExpression
        )

        return value
    }

    private var blocks: [MarkdownBlock] {
        MarkdownBlockParser.parse(normalizedMarkdown)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(blocks) { block in
                blockView(block)
            }
        }
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case let .markdown(id, content):
            MarkdownAttributedBlock(
                content: content,
                color: color,
                id: id
            )

        case let .code(id, language, content):
            MarkdownCodeBlock(
                language: language,
                content: content,
                color: color,
                id: id
            )

        case let .details(id, summary, content):
            MarkdownDetailsBlock(
                summary: summary,
                content: content,
                color: color,
                id: id
            )

        case let .blank(id):
            Color.clear
                .frame(height: 8)
                .id(id)
        }
    }
}

private enum MarkdownBlock: Identifiable {
    case markdown(UUID, String)
    case code(UUID, language: String?, content: String)
    case details(UUID, summary: String, content: String)
    case blank(UUID)

    var id: UUID {
        switch self {
        case let .markdown(id, _):
            return id
        case let .code(id, _, _):
            return id
        case let .details(id, _, _):
            return id
        case let .blank(id):
            return id
        }
    }
}

private enum MarkdownBlockParser {
    static func parse(_ markdown: String) -> [MarkdownBlock] {
        let lines = markdown.components(separatedBy: "\n")
        var blocks: [MarkdownBlock] = []
        var index = 0

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                blocks.append(.blank(UUID()))
                index += 1
            } else if trimmed.lowercased().hasPrefix("<details") {
                let result = parseDetails(lines: lines, startIndex: index)
                blocks.append(.details(UUID(), summary: result.summary, content: result.content))
                index = result.nextIndex
            } else if trimmed.hasPrefix("```") {
                let result = parseCodeBlock(lines: lines, startIndex: index)
                blocks.append(.code(UUID(), language: result.language, content: result.content))
                index = result.nextIndex
            } else {
                let result = parseTextBlock(lines: lines, startIndex: index)
                blocks.append(.markdown(UUID(), result.content))
                index = result.nextIndex
            }
        }
        return blocks
    }

    private static func parseTextBlock(lines: [String], startIndex: Int) -> TextBlockResult {
        var markdownLines: [String] = [lines[startIndex]]
        var index = startIndex + 1

        while index < lines.count {
            let nextTrimmed = lines[index].trimmingCharacters(in: .whitespaces).lowercased()

            if nextTrimmed.isEmpty || nextTrimmed.hasPrefix("```") || nextTrimmed.hasPrefix("<details") {
                break
            }
            markdownLines.append(lines[index])
            index += 1
        }

        let content = makeMarkdownBlock(from: markdownLines)
        return TextBlockResult(content: content, nextIndex: index)
    }

    private static func parseCodeBlock(lines: [String], startIndex: Int) -> CodeBlockResult {
        let opening = lines[startIndex].trimmingCharacters(in: .whitespaces)
        let languageText = String(opening.dropFirst(3)).trimmingCharacters(in: .whitespaces)
        let language = languageText.isEmpty ? nil : languageText

        var codeLines: [String] = []
        var index = startIndex + 1

        while index < lines.count {
            let line = lines[index].trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("```") {
                index += 1
                break
            }
            codeLines.append(lines[index])
            index += 1
        }

        return CodeBlockResult(
            language: language,
            content: codeLines.joined(separator: "\n"),
            nextIndex: index
        )
    }

    private static func parseDetails(lines: [String], startIndex: Int) -> DetailsBlockResult {
        var index = startIndex
        let summary = extractDetailsSummary(lines: lines, index: &index)
        let content = extractDetailsContent(lines: lines, index: &index)

        return DetailsBlockResult(summary: summary, content: content, nextIndex: index)
    }

    private static func extractDetailsSummary(lines: [String], index: inout Int) -> String {
        var summary = "Details"
        let opening = lines[index]

        if let start = opening.range(of: "<summary>", options: .caseInsensitive),
           let end = opening.range(of: "</summary>", options: .caseInsensitive)
        {
            summary = String(opening[start.upperBound ..< end.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        index += 1

        guard index < lines.count else { return summary }

        let summaryLine = lines[index]
        if summaryLine.trimmingCharacters(in: .whitespaces).lowercased().hasPrefix("<summary>") {
            if let start = summaryLine.range(of: "<summary>", options: .caseInsensitive),
               let end = summaryLine.range(of: "</summary>", options: .caseInsensitive)
            {
                summary = String(summaryLine[start.upperBound ..< end.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            index += 1
        }
        return summary
    }

    private static func extractDetailsContent(lines: [String], index: inout Int) -> String {
        var contentLines: [String] = []
        var depth = 1

        while index < lines.count {
            let current = lines[index].trimmingCharacters(in: .whitespaces).lowercased()

            if current.hasPrefix("<details") {
                depth += 1
            }
            if current.hasPrefix("</details") {
                depth -= 1
                if depth == 0 {
                    index += 1
                    break
                }
            }
            if depth > 0 {
                contentLines.append(lines[index])
            }
            index += 1
        }
        return contentLines.joined(separator: "\n")
    }

    private static func makeMarkdownBlock(from lines: [String]) -> String {
        guard lines.count > 1 else {
            return lines[0]
        }

        let result = lines.enumerated().map { index, line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("#") ||
                trimmed.hasPrefix(">") ||
                trimmed.hasPrefix("- ") ||
                trimmed.hasPrefix("* ") ||
                trimmed.hasPrefix("+ ") ||
                trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil
            {
                return line
            }

            if index < lines.count - 1 {
                return line + "  "
            }
            return line
        }
        return result.joined(separator: "\n")
    }

    private struct CodeBlockResult {
        let language: String?
        let content: String
        let nextIndex: Int
    }

    private struct DetailsBlockResult {
        let summary: String
        let content: String
        let nextIndex: Int
    }

    private struct TextBlockResult {
        let content: String
        let nextIndex: Int
    }
}

private struct MarkdownAttributedBlock: View {
    let content: String
    let color: Color
    let id: UUID

    var body: some View {
        if let attributedString = try? AttributedString(
            markdown: content,
            options: markdownOptions
        ) {
            Text(attributedString)
                .foregroundStyle(color)
                .textSelection(.enabled)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
                .id(id)
        } else {
            Text(content)
                .foregroundStyle(color)
                .textSelection(.enabled)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
                .id(id)
        }
    }

    private var markdownOptions:
        AttributedString.MarkdownParsingOptions
    {
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .full
        options.failurePolicy =
            .returnPartiallyParsedIfPossible
        return options
    }
}

private struct MarkdownCodeBlock: View {
    let language: String?
    let content: String
    let color: Color
    let id: UUID

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let language, !language.isEmpty {
                Text(language.uppercased())
                    .font(
                        .caption2.weight(.semibold)
                    )
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                Text(content)
                    .font(
                        .system(
                            size: 12,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(color.opacity(0.95))
                    .textSelection(.enabled)
                    .padding(12)
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            Color.black.opacity(0.35)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
            .stroke(
                Color.white.opacity(0.08),
                lineWidth: 1
            )
        )
        .id(id)
    }
}

private struct MarkdownDetailsBlock: View {
    let summary: String
    let content: String
    let color: Color
    let id: UUID

    @State private var isExpanded = false

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(
                        systemName: isExpanded
                            ? "chevron.down"
                            : "chevron.right"
                    )
                    .font(
                        .caption.weight(.semibold)
                    )
                    .foregroundStyle(.cyan)

                    Text(summary)
                        .font(
                            .subheadline.weight(.semibold)
                        )
                        .foregroundStyle(color)

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                MarkdownText(
                    content,
                    color: color
                )
                .padding(.leading, 18)
                .transition(.opacity)
            }
        }
        .padding(12)
        .background(
            Color.white.opacity(0.04)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
            .stroke(
                Color.white.opacity(0.06),
                lineWidth: 1
            )
        )
        .id(id)
    }
}
