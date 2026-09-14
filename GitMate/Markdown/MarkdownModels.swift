//
//  MarkdownModels.swift
//  GitMate
//

import SwiftUI

enum MarkdownBlock: Identifiable {
    case markdown(UUID, String)
    case inline(UUID, [InlineElement])
    case heading(UUID, level: Int, text: String)
    case code(UUID, language: String?, content: String)
    case details(UUID, summary: String, content: String)
    case list(UUID, items: [String])
    case image(UUID, url: URL, alt: String)
    case callout(UUID, type: CalloutType, content: String)
    case table(UUID, headers: [String], rows: [[String]])
    case hr(UUID)
    case blank(UUID)
    case quote(UUID, String)

    var id: UUID {
        switch self {
        case let .markdown(id, _): return id
        case let .heading(id, _, _): return id
        case let .code(id, _, _): return id
        case let .details(id, _, _): return id
        case let .list(id, _): return id
        case let .image(id, _, _): return id
        case let .callout(id, _, _): return id
        case let .table(id, _, _): return id
        case let .hr(id): return id
        case let .blank(id): return id
        case let .inline(id, _): return id
        case let .quote(id, _): return id
        }
    }
}

enum CalloutType {
    case important
    case note

    var title: String {
        switch self {
        case .important:
            return "Important"
        case .note:
            return "Note"
        }
    }

    var icon: String {
        switch self {
        case .important:
            return "exclamationmark.triangle.fill"
        case .note:
            return "info.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .important:
            return .orange
        case .note:
            return .blue
        }
    }
}

enum InlineElement {
    case text(String)
    case link(text: String, url: URL)
    case image(alt: String, url: URL)
    case linkedImage(url: URL, linkURL: URL, widthHint: CGFloat?)
    case icon(name: String)
}

struct ListBlockResult {
    let items: [String]
    let nextIndex: Int
}

struct CodeBlockResult {
    let language: String?
    let content: String
    let nextIndex: Int
}

struct DetailsBlockResult {
    let summary: String
    let content: String
    let nextIndex: Int
}

struct TextBlockResult {
    let content: String
    let nextIndex: Int
}
