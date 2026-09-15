//
//  MarkdownBlockParser.swift
//  GitMate
//

import Foundation

enum MarkdownBlockParser {
    // MARK: - Internal Types

    private struct CalloutParseResult {
        let type: CalloutType
        let content: String
        let nextIndex: Int
    }

    private struct CalloutInfo {
        let type: CalloutType
        let prefixLength: Int
        let isBlockquote: Bool
    }

    // MARK: - Core Parsing

    static func parse(_ markdown: String, baseURL: URL?) -> [MarkdownBlock] {
        let lines = markdown.components(separatedBy: "\n")
        var blocks: [MarkdownBlock] = []
        var index = 0

        while index < lines.count {
            let result = parseNext(lines: lines, index: index, baseURL: baseURL)
            blocks.append(contentsOf: result.blocks)
            index = result.nextIndex
        }
        return blocks
    }

    // MARK: - Block Category Parsers

    private static func parseNext(lines: [String], index: Int, baseURL: URL?) -> (blocks: [MarkdownBlock], nextIndex: Int) {
        let trimmed = lines[index].trimmingCharacters(in: .whitespaces)

        if let result = parseWhitespaceOrRule(trimmed: trimmed, index: index) {
            return result
        }
        if let result = parseHTMLBlock(lines: lines, index: index, trimmed: trimmed, baseURL: baseURL) {
            return result
        }
        if let result = parseMarkdownBlock(lines: lines, index: index, trimmed: trimmed, baseURL: baseURL) {
            return result
        }

        return parseTextOrInline(lines: lines, index: index, trimmed: trimmed, baseURL: baseURL)
    }

    private static func parseWhitespaceOrRule(trimmed: String, index: Int) -> (blocks: [MarkdownBlock], nextIndex: Int)? {
        if trimmed.isEmpty {
            return ([.blank(UUID())], index + 1)
        } else if isBreakOnlyLine(trimmed) {
            var blocks: [MarkdownBlock] = []
            for _ in 0 ..< max(countBreaks(in: trimmed), 1) {
                blocks.append(.blank(UUID()))
            }
            return (blocks, index + 1)
        } else if isHorizontalRule(trimmed) {
            return ([.hr(UUID())], index + 1)
        }
        return nil
    }

    private static func parseHTMLBlock(lines: [String], index: Int, trimmed: String, baseURL: URL?) -> (blocks: [MarkdownBlock], nextIndex: Int)? {
        if let divResult = MarkdownHTMLParser.parseDivBlock(lines: lines, startIndex: index) {
            return (parse(divResult.innerContent, baseURL: baseURL), divResult.nextIndex)
        } else if let pResult = MarkdownHTMLParser.parsePBlock(lines: lines, startIndex: index) {
            return (parse(pResult.innerContent, baseURL: baseURL), pResult.nextIndex)
        } else if let pictureResult = MarkdownHTMLParser.parsePictureBlock(lines: lines, startIndex: index, baseURL: baseURL) {
            var blocks: [MarkdownBlock] = []
            if let image = pictureResult.image {
                blocks.append(.image(UUID(), url: image.url, alt: image.alt))
            }
            return (blocks, pictureResult.nextIndex)
        } else if let htmlHeading = MarkdownHTMLParser.parseHTMLHeadingBlock(lines: lines, startIndex: index, baseURL: baseURL) {
            var blocks: [MarkdownBlock] = htmlHeading.images.map { .image(UUID(), url: $0.url, alt: $0.alt) }
            if !htmlHeading.text.isEmpty {
                blocks.append(.heading(UUID(), level: htmlHeading.level, text: htmlHeading.text))
            }
            return (blocks, htmlHeading.nextIndex)
        } else if let anchorResult = MarkdownHTMLParser.parseAnchorBlock(lines: lines, startIndex: index, baseURL: baseURL) {
            let blocks: [MarkdownBlock] = anchorResult.elements.isEmpty ? [] : [.inline(UUID(), anchorResult.elements)]
            return (blocks, anchorResult.nextIndex)
        } else if trimmed.lowercased().hasPrefix("<table") {
            let result = MarkdownHTMLParser.parseImageTable(lines: lines, startIndex: index, baseURL: baseURL)
            let blocks = result.images.map { MarkdownBlock.image(UUID(), url: $0.url, alt: $0.alt) }
            return (blocks, result.nextIndex)
        }
        return nil
    }

    private static func parseMarkdownBlock(lines: [String], index: Int, trimmed: String, baseURL: URL?) -> (blocks: [MarkdownBlock], nextIndex: Int)? {
        if trimmed.lowercased().hasPrefix("<details") {
            let result = parseDetails(lines: lines, startIndex: index)
            return ([.details(UUID(), summary: result.summary, content: result.content)], result.nextIndex)
        } else if trimmed.hasPrefix("```") {
            let result = parseCodeBlock(lines: lines, startIndex: index)
            return ([.code(UUID(), language: result.language, content: result.content)], result.nextIndex)
        } else if let heading = parseHeadingLine(trimmed) {
            return (extractHeadingBlocks(heading: heading, baseURL: baseURL), index + 1)
        } else if isListItem(trimmed) {
            let result = parseList(lines: lines, startIndex: index)
            return ([.list(UUID(), items: result.items)], result.nextIndex)
        } else if let image = MarkdownURLResolver.extractImage(from: trimmed, baseURL: baseURL) {
            return ([.image(UUID(), url: image.url, alt: image.alt)], index + 1)
        } else if let tableResult = MarkdownTableParser.parseTable(lines: lines, startIndex: index) {
            return ([.table(UUID(), headers: tableResult.headers, rows: tableResult.rows)], tableResult.nextIndex)
        } else if let callout = parseCalloutLine(lines: lines, startIndex: index) {
            return ([.callout(UUID(), type: callout.type, content: callout.content)], callout.nextIndex)
        } else if trimmed.hasPrefix(">") {
            return ([.quote(UUID(), String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces))], index + 1)
        }
        return nil
    }

    private static func extractHeadingBlocks(heading: (level: Int, text: String), baseURL: URL?) -> [MarkdownBlock] {
        let headingElements = MarkdownInlineParser.parseInlineElements(from: heading.text, baseURL: baseURL)
        var leadingTextParts: [String] = []
        var richTrailingElements: [InlineElement] = []
        var seenRich = false
        var leftoverHTMLText = ""
        var blocks: [MarkdownBlock] = []

        for element in headingElements {
            switch element {
            case let .text(text) where !seenRich:
                if text.trimmingCharacters(in: .whitespaces).hasPrefix("<") {
                    leftoverHTMLText += text
                } else {
                    leadingTextParts.append(text)
                }
            case let .text(text) where seenRich:
                if text.trimmingCharacters(in: .whitespaces).hasPrefix("<") {
                    leftoverHTMLText += text
                } else {
                    richTrailingElements.append(.text(text))
                }
            default:
                seenRich = true; richTrailingElements.append(element)
            }
        }

        let headingText = leadingTextParts.joined().trimmingCharacters(in: .whitespaces)
        if !headingText.isEmpty {
            blocks.append(.heading(UUID(), level: heading.level, text: headingText))
        }

        let richBadges = richTrailingElements.filter {
            if case let .text(text) = $0 {
                return !text.trimmingCharacters(in: .whitespaces).isEmpty
            }
            return true
        }

        if !richBadges.isEmpty {
            blocks.append(.inline(UUID(), richBadges))
        }

        let leftover = leftoverHTMLText.trimmingCharacters(in: .whitespaces)
        if !leftover.isEmpty {
            blocks.append(contentsOf: parse(leftover, baseURL: baseURL))
        }

        return blocks
    }

    private static func parseTextOrInline(lines: [String], index: Int, trimmed: String, baseURL: URL?) -> (blocks: [MarkdownBlock], nextIndex: Int) {
        let elements = MarkdownInlineParser.parseInlineElements(from: trimmed, baseURL: baseURL)
        let hasRichElement = elements.contains {
            if case .text = $0 {
                return false
            }
            if case .link = $0 {
                return false
            }
            return true
        }

        if hasRichElement {
            return ([.inline(UUID(), elements)], index + 1)
        } else {
            let result = parseTextBlock(lines: lines, startIndex: index, baseURL: baseURL)
            return ([.markdown(UUID(), result.content)], result.nextIndex)
        }
    }

    // MARK: - Original Helpers

    private static func isBreakOnlyLine(_ trimmed: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: #"^(<br\s*/?>)+$"#, options: .caseInsensitive) else { return false }
        return regex.firstMatch(in: trimmed, range: NSRange(location: 0, length: (trimmed as NSString).length)) != nil
    }

    private static func countBreaks(in trimmed: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: #"<br\s*/?>"#, options: .caseInsensitive) else { return 1 }
        return regex.numberOfMatches(in: trimmed, range: NSRange(location: 0, length: (trimmed as NSString).length))
    }

    private static func isHorizontalRule(_ line: String) -> Bool {
        let lower = line.lowercased()
        if lower == "<hr>" || lower == "<hr/>" || lower == "<hr />" {
            return true
        }
        return line.range(of: "^(?:\\s*[-_*]){3,}\\s*$", options: .regularExpression) != nil
    }

    private static func identifyCalloutType(from line: String) -> CalloutInfo? {
        let lowercased = line.lowercased()
        if lowercased.hasPrefix("> [!important]") {
            return CalloutInfo(type: .important, prefixLength: "> [!important]".count, isBlockquote: true)
        } else if lowercased.hasPrefix("> [!note]") {
            return CalloutInfo(type: .note, prefixLength: "> [!note]".count, isBlockquote: true)
        } else if lowercased == "!important" || lowercased.hasPrefix("!important ") {
            return CalloutInfo(type: .important, prefixLength: "!important".count, isBlockquote: false)
        } else if lowercased == "!note" || lowercased.hasPrefix("!note ") {
            return CalloutInfo(type: .note, prefixLength: "!note".count, isBlockquote: false)
        }
        return nil
    }

    private static func isCalloutBreakCondition(_ trimmed: String) -> Bool {
        if trimmed.isEmpty || trimmed.hasPrefix("```") || trimmed.hasPrefix("#") || isListItem(trimmed) {
            return true
        }
        let lower = trimmed.lowercased()
        if lower.hasPrefix("<details") || lower.hasPrefix("<table") {
            return true
        }
        return MarkdownURLResolver.extractImage(from: trimmed, baseURL: nil) != nil
    }

    private static func parseCalloutLine(lines: [String], startIndex: Int) -> CalloutParseResult? {
        guard startIndex < lines.count else { return nil }
        let firstLine = lines[startIndex].trimmingCharacters(in: .whitespacesAndNewlines)

        guard let calloutInfo = identifyCalloutType(from: firstLine) else { return nil }

        var contentLines: [String] = []
        let firstContent = String(firstLine.dropFirst(calloutInfo.prefixLength)).trimmingCharacters(in: .whitespacesAndNewlines)
        if !firstContent.isEmpty {
            contentLines.append(firstContent)
        }

        var index = startIndex + 1
        while index < lines.count {
            var trimmed = lines[index].trimmingCharacters(in: .whitespacesAndNewlines)
            if calloutInfo.isBlockquote, trimmed.hasPrefix(">") {
                trimmed = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if isCalloutBreakCondition(trimmed) {
                break
            }
            contentLines.append(trimmed)
            index += 1
        }

        guard !contentLines.isEmpty else {
            return CalloutParseResult(type: calloutInfo.type, content: "", nextIndex: index)
        }
        return CalloutParseResult(type: calloutInfo.type, content: contentLines.joined(separator: "\n"), nextIndex: index)
    }

    private static func isListItem(_ trimmed: String) -> Bool {
        trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ")
    }

    private static func parseList(lines: [String], startIndex: Int) -> ListBlockResult {
        var items: [String] = []
        var index = startIndex
        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if isListItem(trimmed) {
                items.append(String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces))
                index += 1
            } else if !items.isEmpty && !trimmed.isEmpty && (line.hasPrefix("  ") || line.hasPrefix("\t")) {
                items[items.count - 1] += "\n" + trimmed
                index += 1
            } else {
                break
            }
        }
        return ListBlockResult(items: items, nextIndex: index)
    }

    private static func parseHeadingLine(_ trimmed: String) -> (level: Int, text: String)? {
        if let match = trimmed.range(of: #"^#{1,6}\s+"#, options: .regularExpression) {
            let hashes = trimmed[..<match.upperBound].filter { $0 == "#" }
            return (hashes.count, String(trimmed[match.upperBound...]).trimmingCharacters(in: .whitespaces))
        }
        let htmlPattern = #"^<h([1-6])[^>]*>(.*?)</h\1>$"#
        if let regex = try? NSRegularExpression(pattern: htmlPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let nsString = trimmed as NSString
            if let match = regex.firstMatch(in: trimmed, range: NSRange(location: 0, length: nsString.length)), let level = Int(nsString.substring(with: match.range(at: 1))) {
                return (level, nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces))
            }
        }
        return nil
    }

    private static func isTextBlockBreak(lines: [String], index: Int, baseURL: URL?) -> Bool {
        let nextTrimmed = lines[index].trimmingCharacters(in: .whitespaces)
        if nextTrimmed.isEmpty {
            return true
        }

        let nextLower = nextTrimmed.lowercased()
        if nextLower.hasPrefix("```") || nextLower.hasPrefix("<details") || isListItem(nextTrimmed) {
            return true
        }

        let nextIsMarkdownHeading = nextTrimmed.range(of: #"^#{1,6}\s"#, options: .regularExpression) != nil
        if nextIsMarkdownHeading {
            return true
        }

        let nextIsHTMLHeading = nextTrimmed.range(of: #"^<h[1-6][^>]*>.*?</h[1-6]>"#, options: [.regularExpression, .caseInsensitive]) != nil
        if nextIsHTMLHeading {
            return true
        }

        if index + 1 < lines.count && nextTrimmed.contains("|") && MarkdownTableParser.isTableSeparatorLine(lines[index + 1].trimmingCharacters(in: .whitespaces)) {
            return true
        }

        if MarkdownURLResolver.extractImage(from: nextTrimmed, baseURL: baseURL) != nil {
            return true
        }
        if parseCalloutLine(lines: lines, startIndex: index) != nil {
            return true
        }

        return false
    }

    private static func parseTextBlock(lines: [String], startIndex: Int, baseURL: URL?) -> TextBlockResult {
        var markdownLines = [lines[startIndex]]
        var index = startIndex + 1
        while index < lines.count {
            if isTextBlockBreak(lines: lines, index: index, baseURL: baseURL) {
                break
            }
            markdownLines.append(lines[index])
            index += 1
        }
        return TextBlockResult(content: makeMarkdownBlock(from: markdownLines), nextIndex: index)
    }

    private static func parseCodeBlock(lines: [String], startIndex: Int) -> CodeBlockResult {
        let opening = lines[startIndex].trimmingCharacters(in: .whitespaces)
        let languageText = String(opening.dropFirst(3)).trimmingCharacters(in: .whitespaces)
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
        return CodeBlockResult(language: languageText.isEmpty ? nil : languageText, content: codeLines.joined(separator: "\n"), nextIndex: index)
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
        if let start = opening.range(of: "<summary>", options: .caseInsensitive), let end = opening.range(of: "</summary>", options: .caseInsensitive) {
            summary = String(opening[start.upperBound ..< end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        index += 1
        guard index < lines.count else { return summary }
        let summaryLine = lines[index]
        if summaryLine.trimmingCharacters(in: .whitespaces).lowercased().hasPrefix("<summary>"),
           let start = summaryLine.range(of: "<summary>", options: .caseInsensitive), let end = summaryLine.range(of: "</summary>", options: .caseInsensitive)
        {
            summary = String(summaryLine[start.upperBound ..< end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
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
        guard lines.count > 1 else { return lines[0] }
        return lines.enumerated().map { index, line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") || trimmed.hasPrefix(">") || trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") || trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil {
                return line
            }
            return index < lines.count - 1 ? line + "  " : line
        }.joined(separator: "\n")
    }
}
