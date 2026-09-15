//
//  MarkdownHTMLParser.swift
//  GitMate
//

import Foundation
import SwiftUI

struct HTMLHeadingParseResult {
    let level: Int
    let text: String
    let images: [(alt: String, url: URL)]
    let nextIndex: Int
}

enum MarkdownHTMLParser {
    static func parsePictureBlock(lines: [String], startIndex: Int, baseURL: URL?) -> (image: (alt: String, url: URL)?, nextIndex: Int)? {
        let trimmed = lines[startIndex].trimmingCharacters(in: .whitespaces)
        guard trimmed.lowercased().hasPrefix("<picture") else { return nil }
        var collected = [trimmed]
        var index = startIndex + 1
        while index < lines.count {
            let line = lines[index]
            collected.append(line)
            if line.lowercased().contains("</picture>") {
                index += 1
                break
            }
            index += 1
        }
        let joined = collected.joined(separator: " ")
        if let img = MarkdownURLResolver.extractAllImages(from: joined, baseURL: baseURL).last {
            return (img, index)
        }
        let srcsetPattern = #"<source\s[^>]*srcset="([^"]+)"[^>]*>"#
        if let regex = try? NSRegularExpression(pattern: srcsetPattern, options: .caseInsensitive) {
            let nsJoined = joined as NSString
            if let match = regex.firstMatch(in: joined, range: NSRange(location: 0, length: nsJoined.length)) {
                let srcsetValue = nsJoined.substring(with: match.range(at: 1))
                let firstURLString = srcsetValue.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces).first ?? srcsetValue
                if let url = MarkdownURLResolver.resolveURL(firstURLString, baseURL: baseURL) {
                    return (("Image", url), index)
                }
            }
        }
        return (nil, index)
    }

    static func parsePBlock(lines: [String], startIndex: Int) -> (innerContent: String, nextIndex: Int)? {
        let trimmed = lines[startIndex].trimmingCharacters(in: .whitespaces)
        guard trimmed.range(of: #"^<p(\s|>)"#, options: .regularExpression) != nil,
              let openTagRange = trimmed.range(of: #"^<p[^>]*>"#, options: [.regularExpression, .caseInsensitive]) else { return nil }
        let sameLineTrailing = String(trimmed[openTagRange.upperBound...])
        if let closeRange = sameLineTrailing.range(of: "</p>", options: .caseInsensitive) {
            return (String(sameLineTrailing[..<closeRange.lowerBound]), startIndex + 1)
        }
        var collected: [String] = []
        var index = startIndex + 1
        if !sameLineTrailing.isEmpty {
            collected.append(sameLineTrailing)
        }
        while index < lines.count {
            let line = lines[index]
            if line.lowercased().contains("</p>") {
                if let closeRange = line.range(of: "</p>", options: .caseInsensitive) {
                    let before = String(line[..<closeRange.lowerBound])
                    if !before.trimmingCharacters(in: .whitespaces).isEmpty {
                        collected.append(before)
                    }
                }
                index += 1
                break
            }
            collected.append(line)
            index += 1
        }
        return (collected.joined(separator: "\n"), index)
    }

    static func parseDivBlock(lines: [String], startIndex: Int) -> (innerContent: String, nextIndex: Int)? {
        let trimmed = lines[startIndex].trimmingCharacters(in: .whitespaces)
        guard trimmed.lowercased().hasPrefix("<div"),
              let openTagRange = trimmed.range(of: #"^<div[^>]*>"#, options: [.regularExpression, .caseInsensitive]) else { return nil }
        var depth = 1
        var collected: [String] = []
        var index = startIndex + 1
        let sameLineTrailing = String(trimmed[openTagRange.upperBound...])
        if !sameLineTrailing.isEmpty {
            collected.append(sameLineTrailing)
        }
        while index < lines.count {
            let line = lines[index]
            let lower = line.lowercased()
            if lower.range(of: #"<div[^>]*>"#, options: .regularExpression) != nil {
                depth += 1
            }
            if lower.contains("</div>") {
                depth -= 1
                if depth == 0 {
                    if let closeRange = line.range(of: "</div>", options: .caseInsensitive) {
                        let before = String(line[..<closeRange.lowerBound])
                        if !before.trimmingCharacters(in: .whitespaces).isEmpty {
                            collected.append(before)
                        }
                    }
                    index += 1
                    break
                }
            }
            collected.append(line)
            index += 1
        }
        return (collected.joined(separator: "\n"), index)
    }

    static func parseHTMLHeadingBlock(lines: [String], startIndex: Int, baseURL: URL?) -> HTMLHeadingParseResult? {
        let trimmed = lines[startIndex].trimmingCharacters(in: .whitespaces)
        guard let openMatch = trimmed.range(of: #"^<h([1-6])[^>]*>"#, options: .regularExpression) else { return nil }
        let openingTag = String(trimmed[openMatch])
        guard let levelChar = openingTag.first(where: { $0.isNumber }), let level = Int(String(levelChar)) else { return nil }
        let closeTagLower = "</h\(level)>"
        if trimmed.lowercased().contains(closeTagLower) {
            return nil
        }
        var collected: [String] = []
        var index = startIndex + 1
        while index < lines.count {
            let line = lines[index]
            let lineTrimmedLower = line.trimmingCharacters(in: .whitespaces).lowercased()
            if lineTrimmedLower.hasPrefix(closeTagLower) || lineTrimmedLower == closeTagLower {
                index += 1
                break
            }
            collected.append(line)
            index += 1
        }
        var images: [(alt: String, url: URL)] = []
        for line in collected {
            images.append(contentsOf: MarkdownURLResolver.extractAllImages(from: line, baseURL: baseURL))
        }
        var text = collected.joined(separator: " ").replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "&nbsp;", with: " ").components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty || !images.isEmpty else { return nil }
        return HTMLHeadingParseResult(level: level, text: text, images: images, nextIndex: index)
    }

    static func parseImageTable(lines: [String], startIndex: Int, baseURL: URL?) -> (images: [(alt: String, url: URL)], nextIndex: Int) {
        var images: [(alt: String, url: URL)] = []
        var index = startIndex
        while index < lines.count {
            let line = lines[index]
            images.append(contentsOf: MarkdownURLResolver.extractAllImages(from: line, baseURL: baseURL))
            if line.lowercased().contains("</table>") {
                index += 1
                break
            }
            index += 1
        }
        return (images, index)
    }

    static func isAnchorLine(_ trimmed: String) -> Bool {
        let lower = trimmed.lowercased()
        let isNbsp = trimmed == "&nbsp;" || trimmed.replacingOccurrences(of: "&nbsp;", with: "").trimmingCharacters(in: .whitespaces).isEmpty
        return lower.contains("<a ") || lower.contains("<a>") || lower.contains("<img ") || lower.contains("</a>") || isNbsp
    }

    static func parseAnchorBlock(lines: [String], startIndex: Int, baseURL: URL?) -> (elements: [InlineElement], nextIndex: Int)? {
        let firstTrimmed = lines[startIndex].trimmingCharacters(in: .whitespaces)
        guard isAnchorLine(firstTrimmed) else { return nil }
        var collected = [firstTrimmed]
        var index = startIndex + 1
        while index < lines.count {
            let trimmedLine = lines[index].trimmingCharacters(in: .whitespaces)
            if trimmedLine.isEmpty {
                var peekIndex = index + 1
                while peekIndex < lines.count, lines[peekIndex].trimmingCharacters(in: .whitespaces).isEmpty {
                    peekIndex += 1
                }
                if peekIndex < lines.count, isAnchorLine(lines[peekIndex].trimmingCharacters(in: .whitespaces)) {
                    index += 1
                    continue
                }
                break
            }
            let trimmedLower = trimmedLine.lowercased()
            let isClosingTag = trimmedLower.hasPrefix("</a>") || trimmedLower.hasPrefix("</p>") || trimmedLower == "</a>" || trimmedLower == "</p>"
            if isAnchorLine(trimmedLine) || isClosingTag {
                collected.append(trimmedLine)
                index += 1
                if isClosingTag {
                    var peekIndex = index
                    while peekIndex < lines.count, lines[peekIndex].trimmingCharacters(in: .whitespaces).isEmpty {
                        peekIndex += 1
                    }
                    if peekIndex < lines.count, isAnchorLine(lines[peekIndex].trimmingCharacters(in: .whitespaces)) {
                        continue
                    }
                    break
                }
            } else {
                break
            }
        }
        let elements = parseAnchorHTML(collected.joined(separator: " "), baseURL: baseURL)
        return elements.isEmpty ? nil : (elements, index)
    }

    static func parseAnchorHTML(_ html: String, baseURL: URL?) -> [InlineElement] {
        var elements: [InlineElement] = []
        let decoded = decodeHTMLString(html)
        let anchorPattern = #"<a\b[^>]*\bhref\s*=\s*"([^"]*)"[^>]*>(.*?)</a>"#
        guard let anchorRegex = try? NSRegularExpression(pattern: anchorPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else { return elements }

        let nsDecoded = decoded as NSString
        let matches = anchorRegex.matches(in: decoded, range: NSRange(location: 0, length: nsDecoded.length))
        var lastIndex = 0

        for match in matches {
            let beforeRange = NSRange(location: lastIndex, length: match.range.location - lastIndex)
            let beforeText = nsDecoded.substring(with: beforeRange).trimmingCharacters(in: .whitespacesAndNewlines)
            if !beforeText.isEmpty {
                elements.append(.text(beforeText))
            }

            let hrefString = nsDecoded.substring(with: match.range(at: 1))
            let innerHTML = nsDecoded.substring(with: match.range(at: 2))
            lastIndex = match.range.upperBound
            let linkURL = MarkdownURLResolver.resolveURL(hrefString, baseURL: baseURL)

            if let element = parseAnchorContent(innerHTML: innerHTML, linkURL: linkURL, baseURL: baseURL) {
                elements.append(element)
            }
        }

        if lastIndex < nsDecoded.length {
            let afterRange = NSRange(location: lastIndex, length: nsDecoded.length - lastIndex)
            let afterText = nsDecoded.substring(with: afterRange).trimmingCharacters(in: .whitespacesAndNewlines)
            if !afterText.isEmpty {
                elements.append(.text(afterText))
            }
        }
        return elements
    }

    private static func decodeHTMLString(_ html: String) -> String {
        html.replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&#160;", with: " ")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
    }

    private static func parseAnchorContent(innerHTML: String, linkURL: URL?, baseURL: URL?) -> InlineElement? {
        if let element = parseImageInAnchor(innerHTML: innerHTML, linkURL: linkURL, baseURL: baseURL) {
            return element
        }

        let visibleText = innerHTML.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !visibleText.isEmpty else { return nil }

        if let linkURL {
            return .link(text: visibleText, url: linkURL)
        } else {
            return .text(visibleText)
        }
    }

    private static func parseImageInAnchor(innerHTML: String, linkURL: URL?, baseURL: URL?) -> InlineElement? {
        guard let linkURL,
              let imgRegex = try? NSRegularExpression(pattern: #"<img\b[^>]*\bsrc\s*=\s*"([^"]+)"[^>]*>"#, options: .caseInsensitive) else { return nil }

        let nsInner = innerHTML as NSString
        guard let imgMatch = imgRegex.firstMatch(in: innerHTML, range: NSRange(location: 0, length: nsInner.length)) else { return nil }

        let imgURLString = nsInner.substring(with: imgMatch.range(at: 1))
        let fullImgTag = nsInner.substring(with: imgMatch.range)
        let widthHint = extractWidthHint(from: fullImgTag)

        guard let imgURL = MarkdownURLResolver.resolveURL(imgURLString, baseURL: baseURL) else { return nil }
        return .linkedImage(url: imgURL, linkURL: linkURL, widthHint: widthHint)
    }

    private static func extractWidthHint(from imgTag: String) -> CGFloat? {
        guard let widthRegex = try? NSRegularExpression(pattern: #"width="(\d+)""#, options: .caseInsensitive) else { return nil }
        let tagNS = imgTag as NSString
        guard let widthMatch = widthRegex.firstMatch(in: imgTag, range: NSRange(location: 0, length: tagNS.length)) else { return nil }
        return Double(tagNS.substring(with: widthMatch.range(at: 1))).map { CGFloat($0) }
    }
}
