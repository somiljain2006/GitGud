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
    let baseURL: URL?

    init(
        _ markdown: String,
        color: Color = .white,
        baseURL: URL? = nil
    ) {
        self.markdown = markdown
        self.color = color
        self.baseURL = baseURL
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
        MarkdownBlockParser.parse(normalizedMarkdown, baseURL: baseURL)
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
            MarkdownAttributedBlock(content: content, color: color, id: id)

        case let .code(id, language, content):
            MarkdownCodeBlock(language: language, content: content, color: color, id: id)

        case let .details(id, summary, content):
            MarkdownDetailsBlock(summary: summary, content: content, color: color, id: id, baseURL: baseURL)

        case let .blank(id):
            Color.clear.frame(height: 8).id(id)

        case let .inline(id, elements):
            MarkdownInlineBlock(elements: elements, color: color, id: id)

        case let .heading(id, level, text):
            MarkdownHeadingBlock(level: level, text: text, color: color, id: id)

        default:
            secondaryBlockView(block)
        }
    }

    @ViewBuilder
    private func secondaryBlockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case let .list(id, items):
            MarkdownListBlock(items: items, color: color, id: id)

        case let .image(id, url, alt):
            MarkdownImageBlock(url: url, alt: alt, id: id)

        case let .callout(id, type, content):
            MarkdownCalloutBlock(type: type, content: content, color: color, id: id)

        case let .hr(id):
            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.vertical, 8)
                .id(id)

        case let .table(id, headers, rows):
            MarkdownTableBlock(headers: headers, rows: rows, color: color, id: id)

        case let .quote(id, content):
            MarkdownQuoteBlock(content: content, color: color, id: id)

        default:
            EmptyView()
        }
    }
}
