//
//  StarFormatter.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import Foundation

enum StarFormatter {
    static func formatStars(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        }
        return "\(count)"
    }
}
