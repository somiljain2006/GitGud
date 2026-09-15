//
//  OrbiSpeaker.swift
//  GitMate
//

import AVFoundation
import Combine
import Foundation

@MainActor
final class OrbiSpeaker: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isSpeaking: Bool = false

    private let synthesizer = AVSpeechSynthesizer()
    var onSpeakingFinished: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        stop()

        let cleanedText = cleanTextForSpeech(text)
        guard !cleanedText.isEmpty else { return }

        let utterance = AVSpeechUtterance(string: cleanedText)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .duckOthers)
        try? AVAudioSession.sharedInstance().setActive(true)

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    private func cleanTextForSpeech(_ text: String) -> String {
        var cleaned = text

        if let regex = try? NSRegularExpression(pattern: "```[\\s\\S]*?```", options: []) {
            cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: NSRange(location: 0, length: cleaned.utf16.count), withTemplate: " [code snippet] ")
        }

        if let regex = try? NSRegularExpression(pattern: "`.*?`", options: []) {
            cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: NSRange(location: 0, length: cleaned.utf16.count), withTemplate: " ")
        }

        cleaned = cleaned.replacingOccurrences(of: "#", with: "")

        if let regex = try? NSRegularExpression(pattern: "\\[(.*?)\\]\\(.*?\\)", options: []) {
            cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: NSRange(location: 0, length: cleaned.utf16.count), withTemplate: "$1")
        }

        let charsToRemove: [Character] = ["*", "_", ">", "-"]
        for char in charsToRemove {
            cleaned = cleaned.replacingOccurrences(of: String(char), with: " ")
        }

        if let regex = try? NSRegularExpression(pattern: "\\s+", options: []) {
            cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: NSRange(location: 0, length: cleaned.utf16.count), withTemplate: " ")
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated func speechSynthesizer(_: AVSpeechSynthesizer, didFinish _: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.onSpeakingFinished?()
        }
    }

    nonisolated func speechSynthesizer(_: AVSpeechSynthesizer, didCancel _: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}
