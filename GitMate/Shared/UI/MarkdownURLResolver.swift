//
//  MarkdownURLResolver.swift
//  GitMate
//

import Foundation

enum MarkdownURLResolver {
    static func resolveURL(_ urlString: String, baseURL: URL?) -> URL? {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)
        var resolvedURL: URL?

        if let url = URL(string: trimmed), url.scheme != nil {
            resolvedURL = url
        } else if let baseURL = baseURL {
            if trimmed.hasPrefix("/") {
                let components = baseURL.pathComponents.filter { $0 != "/" }
                if components.count >= 3 {
                    let repoRoot = components.prefix(3).joined(separator: "/")
                    let fullPath = "/\(repoRoot)\(trimmed)"
                    var comps = URLComponents()
                    comps.scheme = baseURL.scheme
                    comps.host = baseURL.host
                    comps.path = fullPath
                    resolvedURL = comps.url
                }
            }
            if resolvedURL == nil {
                resolvedURL = URL(string: trimmed, relativeTo: baseURL)?.absoluteURL
            }
        }

        if let url = resolvedURL,
           url.host == "github.com",
           url.pathComponents.count >= 4,
           url.pathComponents[3] == "blob"
        {
            var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
            comps?.host = "raw.githubusercontent.com"
            var newPathComponents = url.pathComponents
            newPathComponents.remove(at: 3)
            comps?.path = newPathComponents.joined(separator: "/").replacingOccurrences(of: "//", with: "/")
            resolvedURL = comps?.url ?? resolvedURL
        }

        return resolvedURL
    }

    static func extractImage(from line: String, baseURL: URL?) -> (alt: String, url: URL)? {
        let mdPattern = #"^!\[([^\]]*)\]\(\s*(\S+?)(?:\s+["'].*?["'])?\s*\)$"#
        if let regex = try? NSRegularExpression(pattern: mdPattern) {
            let nsString = line as NSString
            if let result = regex.firstMatch(in: line, range: NSRange(location: 0, length: nsString.length)) {
                let alt = nsString.substring(with: result.range(at: 1))
                let urlString = nsString.substring(with: result.range(at: 2))
                if let url = resolveURL(urlString, baseURL: baseURL) {
                    return (alt, url)
                }
            }
        }

        let htmlPattern = #"^\<img[^>]+src="([^">]+)"[^>]*\/?\>$"#
        if let regex = try? NSRegularExpression(pattern: htmlPattern, options: .caseInsensitive) {
            let nsString = line as NSString
            if let result = regex.firstMatch(in: line, range: NSRange(location: 0, length: nsString.length)) {
                let urlString = nsString.substring(with: result.range(at: 1))
                var alt = "Image"
                if let altRegex = try? NSRegularExpression(pattern: #"alt="([^">]*)""#, options: .caseInsensitive),
                   let altResult = altRegex.firstMatch(in: line, range: NSRange(location: 0, length: nsString.length))
                {
                    alt = nsString.substring(with: altResult.range(at: 1))
                }
                if let url = resolveURL(urlString, baseURL: baseURL) {
                    return (alt, url)
                }
            }
        }
        return nil
    }

    static func extractAllImages(from line: String, baseURL: URL?) -> [(alt: String, url: URL)] {
        var results: [(alt: String, url: URL)] = []
        let pattern = "<img[^>]+src=\"([^\">]+)\"[^>]*>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return results }
        let nsString = line as NSString
        let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsString.length))
        for match in matches {
            let fullTag = nsString.substring(with: match.range)
            let urlString = nsString.substring(with: match.range(at: 1))
            guard let url = resolveURL(urlString, baseURL: baseURL) else { continue }
            var alt = "Image"
            if let altRegex = try? NSRegularExpression(pattern: "alt=\"([^\">]*)\"", options: .caseInsensitive) {
                let tagNS = fullTag as NSString
                if let altMatch = altRegex.firstMatch(in: fullTag, range: NSRange(location: 0, length: tagNS.length)) {
                    alt = tagNS.substring(with: altMatch.range(at: 1))
                }
            }
            results.append((alt, url))
        }
        return results
    }
}
