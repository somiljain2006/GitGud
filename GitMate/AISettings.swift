//
//  AISettings.swift
//  GitMate
//
//  Created by somil jain on 12/09/26.
//

import Foundation

struct AISettings {
    var model: String
    var apiKey: String
    var baseURL: String

    static let `default` = AISettings(
        model: "",
        apiKey: "",
        baseURL: ""
    )
}
