//
//  DateFormatter+Relative.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import Foundation

enum RelativeDateFormatter {
    static func relativeString(from isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return "Recently" }
        
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .abbreviated
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}
