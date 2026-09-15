//
//  OrbiVoiceState.swift
//  GitMate
//

import Foundation

enum OrbiVoiceState: Equatable {
    case idle
    case listeningForWakePhrase
    case wakePhraseDetected
    case listeningForPrompt
    case processing
    case speaking
    case error(String)

    var displayText: String {
        switch self {
        case .idle:
            return "Say Hey Orbi"
        case .listeningForWakePhrase:
            return "Listening for Hey Orbi…"
        case .wakePhraseDetected:
            return "Yes?"
        case .listeningForPrompt:
            return "Listening…"
        case .processing:
            return "Orbi is thinking…"
        case .speaking:
            return "Orbi is speaking…"
        case let .error(message):
            return message
        }
    }
}
