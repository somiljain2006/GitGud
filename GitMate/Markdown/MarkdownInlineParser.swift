//
//  MarkdownInlineParser.swift
//  GitMate
//

import Foundation
import SwiftUI

enum MarkdownInlineParser {
    private static let emojiShortcodes: [String: (sfSymbol: String?, emoji: String)] = [
        ":link:": ("link", "🔗"), ":warning:": ("exclamationmark.triangle.fill", "⚠️"),
        ":information_source:": ("info.circle.fill", "ℹ️"), ":exclamation:": ("exclamationmark.circle.fill", "❗"),
        ":question:": ("questionmark.circle", "❓"), ":bulb:": ("lightbulb.fill", "💡"),
        ":memo:": ("doc.text", "📝"), ":pencil:": ("pencil", "✏️"),
        ":clipboard:": ("doc.on.clipboard", "📋"), ":books:": ("books.vertical.fill", "📚"),
        ":book:": ("book.fill", "📖"), ":notebook:": ("notebook", "📓"),
        ":page_facing_up:": ("doc.text.fill", "📄"), ":file_folder:": ("folder.fill", "📁"),
        ":open_file_folder:": ("folder.fill.badge.plus", "📂"), ":package:": ("shippingbox.fill", "📦"),
        ":inbox_tray:": ("tray.and.arrow.down.fill", "📥"), ":outbox_tray:": ("tray.and.arrow.up.fill", "📤"),
        ":mailbox:": ("envelope.fill", "📬"), ":email:": ("envelope.fill", "📧"),
        ":speech_balloon:": ("bubble.left.fill", "💬"), ":white_check_mark:": ("checkmark.circle.fill", "✅"),
        ":x:": ("xmark.circle.fill", "❌"), ":heavy_check_mark:": ("checkmark", "✔️"),
        ":negative_squared_cross_mark:": ("xmark.square.fill", "❎"), ":o:": ("circle", "⭕"),
        ":100:": (nil, "💯"), ":soon:": ("arrow.right.circle", "🔜"), ":new:": ("sparkles", "🆕"),
        ":free:": (nil, "🆓"), ":sos:": ("sos", "🆘"), ":no_entry:": ("nosign", "⛔"),
        ":no_entry_sign:": ("nosign", "🚫"), ":lock:": ("lock.fill", "🔒"), ":unlock:": ("lock.open.fill", "🔓"),
        ":key:": ("key.fill", "🔑"), ":shield:": ("shield.fill", "🛡️"), ":star:": ("star.fill", "⭐"),
        ":star2:": ("star.fill", "🌟"), ":fire:": ("flame.fill", "🔥"), ":rocket:": ("airplane", "🚀"),
        ":zap:": ("bolt.fill", "⚡"), ":sparkles:": ("sparkles", "✨"), ":tada:": ("party.popper", "🎉"),
        ":bug:": ("ant.fill", "🐛"), ":construction:": ("hammer.fill", "🚧"), ":wrench:": ("wrench.fill", "🔧"),
        ":gear:": ("gearshape.fill", "⚙️"), ":hammer:": ("hammer.fill", "🔨"),
        ":hammer_and_wrench:": ("hammer.fill", "🛠️"), ":toolbox:": ("wrench.and.screwdriver.fill", "🧰"),
        ":test_tube:": ("testtube.2", "🧪"), ":microscope:": ("microscope", "🔬"),
        ":magnet:": ("magnet.fill", "🧲"), ":computer:": ("desktopcomputer", "💻"),
        ":iphone:": ("iphone", "📱"), ":wave:": ("hand.wave.fill", "👋"),
        ":point_right:": ("hand.point.right.fill", "👉"), ":point_left:": ("hand.point.left.fill", "👈"),
        ":point_up:": ("hand.point.up.fill", "☝️"), ":thumbsup:": ("hand.thumbsup.fill", "👍"),
        ":thumbsdown:": ("hand.thumbsdown.fill", "👎"), ":clap:": ("hands.clap.fill", "👏"),
        ":raised_hands:": ("hands.sparkles.fill", "🙌"), ":pray:": ("hands.and.sparkles.fill", "🙏"),
        ":eyes:": ("eyes", "👀"), ":heart:": ("heart.fill", "❤️"), ":broken_heart:": ("heart.slash.fill", "💔"),
        ":smile:": ("face.smiling.fill", "😄"), ":laughing:": (nil, "😆"), ":sob:": (nil, "😭"),
        ":thinking:": (nil, "🤔"), ":man_technologist:": ("person.fill", "👨‍💻"),
        ":woman_technologist:": ("person.fill", "👩‍💻"), ":arrow_right:": ("arrow.right", "➡️"),
        ":arrow_left:": ("arrow.left", "⬅️"), ":arrow_up:": ("arrow.up", "⬆️"),
        ":arrow_down:": ("arrow.down", "⬇️"), ":arrows_counterclockwise:": ("arrow.counterclockwise", "🔄"),
        ":repeat:": ("repeat", "🔁"), ":fast_forward:": ("forward.fill", "⏩"),
        ":art:": ("paintpalette.fill", "🎨"), ":chart_with_upwards_trend:": ("chart.line.uptrend.xyaxis", "📈"),
        ":chart_with_downwards_trend:": ("chart.line.downtrend.xyaxis", "📉"), ":bar_chart:": ("chart.bar.fill", "📊"),
        ":calendar:": ("calendar", "📅"), ":clock:": ("clock.fill", "🕐"), ":timer:": ("timer", "⏱️"),
        ":hourglass:": ("hourglass", "⌛"), ":globe:": ("globe", "🌍"), ":world_map:": ("map.fill", "🗺️"),
        ":house:": ("house.fill", "🏠"), ":office:": ("building.2.fill", "🏢"), ":trophy:": ("trophy.fill", "🏆"),
        ":medal:": ("medal.fill", "🥇"), ":gem:": ("seal.fill", "💎"), ":moneybag:": ("dollarsign.circle.fill", "💰"),
        ":credit_card:": ("creditcard.fill", "💳"), ":shopping_cart:": ("cart.fill", "🛒"), ":label:": ("tag.fill", "🏷️"),
        ":mag:": ("magnifyingglass", "🔍"), ":mag_right:": ("magnifyingglass", "🔎"),
        ":loudspeaker:": ("megaphone.fill", "📢"), ":bell:": ("bell.fill", "🔔"), ":no_bell:": ("bell.slash.fill", "🔕"),
        ":pushpin:": ("pin.fill", "📌"), ":paperclip:": ("paperclip", "📎"), ":scissors:": ("scissors", "✂️"),
        ":wastebasket:": ("trash.fill", "🗑️"), ":recycle:": ("arrow.triangle.2.circlepath", "♻️"),
        ":electric_plug:": ("powerplug.fill", "🔌"), ":battery:": ("battery.100", "🔋"),
        ":camera:": ("camera.fill", "📷"), ":movie_camera:": ("video.fill", "🎥"),
        ":headphones:": ("headphones", "🎧"), ":musical_note:": ("music.note", "🎵"),
        ":notes:": ("music.note.list", "🎶"), ":pizza:": (nil, "🍕"), ":coffee:": ("cup.and.saucer.fill", "☕"),
    ]

    static func parseInlineElements(from line: String, baseURL: URL?) -> [InlineElement] {
        if line.range(of: #"<a\b[^>]*>.*?</a>"#, options: [.regularExpression, .caseInsensitive]) != nil {
            return parseMixedInlineHTML(line, baseURL: baseURL)
        }

        var elements: [InlineElement] = []
        var remaining = line

        while !remaining.isEmpty {
            guard let match = findNextMatch(in: remaining) else {
                elements.append(.text(remaining))
                break
            }

            if match.range.lowerBound > remaining.startIndex {
                elements.append(.text(String(remaining[..<match.range.lowerBound])))
            }

            let result = processMatch(type: match.type, matchRange: match.range, remaining: remaining, baseURL: baseURL)
            elements.append(contentsOf: result.elements)
            remaining = result.remaining
        }

        return elements
    }

    private static func findNextMatch(in text: String) -> (type: Int, range: Range<String.Index>)? {
        var bestMatch: (type: Int, range: Range<String.Index>)?

        func updateBest(type: Int, pattern: String) {
            if let range = text.range(of: pattern) {
                if let currentBest = bestMatch {
                    if range.lowerBound < currentBest.range.lowerBound {
                        bestMatch = (type, range)
                    }
                } else {
                    bestMatch = (type, range)
                }
            }
        }

        updateBest(type: 1, pattern: "[![")
        updateBest(type: 2, pattern: "![")
        updateBest(type: 3, pattern: "[")

        for (shortcode, _) in emojiShortcodes {
            updateBest(type: 4, pattern: shortcode)
        }

        return bestMatch
    }

    private static func processMatch(type: Int, matchRange: Range<String.Index>, remaining: String, baseURL: URL?) -> (elements: [InlineElement], remaining: String) {
        switch type {
        case 1: return processLinkedImage(matchRange: matchRange, remaining: remaining, baseURL: baseURL)
        case 2: return processImage(matchRange: matchRange, remaining: remaining, baseURL: baseURL)
        case 3: return processLink(matchRange: matchRange, remaining: remaining, baseURL: baseURL)
        case 4: return processEmoji(matchRange: matchRange, remaining: remaining)
        default: return processFallback(type: type, matchRange: matchRange, remaining: remaining)
        }
    }

    private static func processEmoji(matchRange: Range<String.Index>, remaining: String) -> (elements: [InlineElement], remaining: String) {
        let matchStart = matchRange.lowerBound
        for (shortcode, value) in emojiShortcodes where remaining[matchStart...].hasPrefix(shortcode) {
            let element: InlineElement
            if let sfSymbol = value.sfSymbol {
                element = .icon(name: sfSymbol)
            } else {
                element = .text(value.emoji)
            }
            let newRemaining = String(remaining[remaining.index(matchStart, offsetBy: shortcode.count)...])
            return ([element], newRemaining)
        }
        return processFallback(type: 4, matchRange: matchRange, remaining: remaining)
    }

    private static func processLinkedImage(matchRange: Range<String.Index>, remaining: String, baseURL: URL?) -> (elements: [InlineElement], remaining: String) {
        let imageContentStart = matchRange.upperBound
        if let altEnd = remaining.range(of: "](", range: imageContentStart ..< remaining.endIndex),
           let imageEnd = remaining.range(of: ")](", range: altEnd.upperBound ..< remaining.endIndex),
           let linkEnd = remaining.range(of: ")", range: imageEnd.upperBound ..< remaining.endIndex)
        {
            let imageURLString = String(remaining[altEnd.upperBound ..< imageEnd.lowerBound])
            let linkURLString = String(remaining[imageEnd.upperBound ..< linkEnd.lowerBound])

            if let imgURL = MarkdownURLResolver.resolveURL(imageURLString, baseURL: baseURL),
               let linkURL = MarkdownURLResolver.resolveURL(linkURLString, baseURL: baseURL)
            {
                return ([.linkedImage(url: imgURL, linkURL: linkURL, widthHint: nil)], String(remaining[linkEnd.upperBound ..< remaining.endIndex]))
            } else {
                return ([.text(String(remaining[matchRange.lowerBound ..< linkEnd.upperBound]))], String(remaining[linkEnd.upperBound ..< remaining.endIndex]))
            }
        }
        return processFallback(type: 1, matchRange: matchRange, remaining: remaining)
    }

    private static func processImage(matchRange: Range<String.Index>, remaining: String, baseURL: URL?) -> (elements: [InlineElement], remaining: String) {
        let imageContentStart = matchRange.upperBound
        if let altEnd = remaining.range(of: "](", range: imageContentStart ..< remaining.endIndex),
           let imageEnd = remaining.range(of: ")", range: altEnd.upperBound ..< remaining.endIndex)
        {
            let alt = String(remaining[imageContentStart ..< altEnd.lowerBound])
            let rawDestination = String(remaining[altEnd.upperBound ..< imageEnd.lowerBound])
            let parts = rawDestination.trimmingCharacters(in: .whitespacesAndNewlines).split(maxSplits: 1, whereSeparator: { $0.isWhitespace })
            let imageURLString = String(parts.first ?? "")

            if let url = MarkdownURLResolver.resolveURL(imageURLString, baseURL: baseURL) {
                return ([.image(alt: alt, url: url)], String(remaining[imageEnd.upperBound ..< remaining.endIndex]))
            } else {
                return ([.text(String(remaining[matchRange.lowerBound ..< imageEnd.upperBound]))], String(remaining[imageEnd.upperBound ..< remaining.endIndex]))
            }
        }
        return processFallback(type: 2, matchRange: matchRange, remaining: remaining)
    }

    private static func processLink(matchRange: Range<String.Index>, remaining: String, baseURL: URL?) -> (elements: [InlineElement], remaining: String) {
        let linkContentStart = matchRange.upperBound
        if let labelEnd = remaining.range(of: "](", range: linkContentStart ..< remaining.endIndex),
           let linkEnd = remaining.range(of: ")", range: labelEnd.upperBound ..< remaining.endIndex)
        {
            let label = String(remaining[linkContentStart ..< labelEnd.lowerBound])
            let urlString = String(remaining[labelEnd.upperBound ..< linkEnd.lowerBound])

            if let url = MarkdownURLResolver.resolveURL(urlString, baseURL: baseURL) {
                return ([.link(text: label, url: url)], String(remaining[linkEnd.upperBound ..< remaining.endIndex]))
            } else {
                return ([.text(String(remaining[matchRange.lowerBound ..< linkEnd.upperBound]))], String(remaining[linkEnd.upperBound ..< remaining.endIndex]))
            }
        }
        return processFallback(type: 3, matchRange: matchRange, remaining: remaining)
    }

    private static func processFallback(type: Int, matchRange: Range<String.Index>, remaining: String) -> (elements: [InlineElement], remaining: String) {
        let matchStart = matchRange.lowerBound
        let advanceBy = type == 1 ? 3 : (type == 2 ? 2 : 1)
        let advanceIndex = remaining.index(matchStart, offsetBy: advanceBy, limitedBy: remaining.endIndex) ?? remaining.endIndex
        return ([.text(String(remaining[matchStart ..< advanceIndex]))], String(remaining[advanceIndex ..< remaining.endIndex]))
    }

    static func parseMixedInlineHTML(_ html: String, baseURL: URL?) -> [InlineElement] {
        let parsed = MarkdownHTMLParser.parseAnchorHTML(html, baseURL: baseURL)
        return parsed.isEmpty ? [.text(html)] : parsed
    }
}
