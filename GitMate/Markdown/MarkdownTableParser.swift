//
//  MarkdownTableParser.swift
//  GitMate
//

import Foundation

enum MarkdownTableParser {
    struct ParsedTable {
        let headers: [String]
        let rows: [[String]]
        let nextIndex: Int
    }

    static func parseTable(lines: [String], startIndex: Int) -> ParsedTable? {
        guard startIndex + 1 < lines.count else { return nil }
        let headerLine = lines[startIndex].trimmingCharacters(in: .whitespaces)
        let separatorLine = lines[startIndex + 1].trimmingCharacters(in: .whitespaces)
        guard headerLine.contains("|"), isTableSeparatorLine(separatorLine) else { return nil }
        let headers = splitTableRow(headerLine)
        guard !headers.isEmpty else { return nil }
        var rows: [[String]] = []
        var index = startIndex + 2
        while index < lines.count {
            let line = lines[index].trimmingCharacters(in: .whitespaces)
            if line.isEmpty || !line.contains("|") {
                break
            }
            rows.append(splitTableRow(line))
            index += 1
        }
        return ParsedTable(headers: headers, rows: rows, nextIndex: index)
    }

    static func isTableSeparatorLine(_ line: String) -> Bool {
        guard line.contains("|") else { return false }
        let cells = splitTableRow(line)
        guard !cells.isEmpty else { return false }
        return cells.allSatisfy { cell in
            let trimmed = cell.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return false }
            return trimmed.allSatisfy { $0 == "-" || $0 == ":" }
        }
    }

    static func splitTableRow(_ line: String) -> [String] {
        var trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("|") {
            trimmed.removeFirst()
        }
        if trimmed.hasSuffix("|") {
            trimmed.removeLast()
        }
        var cells: [String] = []
        var current = ""
        var previousWasBackslash = false
        for char in trimmed {
            if char == "|", !previousWasBackslash {
                cells.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
            previousWasBackslash = (char == "\\")
        }
        cells.append(current.trimmingCharacters(in: .whitespaces))
        return cells
    }
}
