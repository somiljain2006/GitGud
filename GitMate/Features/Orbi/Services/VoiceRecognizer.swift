//
//  VoiceRecognizer.swift
//  GitMate
//

import AVFoundation
import Combine
import Foundation
import Speech

protocol WakeWordDetecting {
    var onWakeWordDetected: (() -> Void)? { get set }
    var onPartialTranscript: ((String) -> Void)? { get set }

    func start()
    func stop()
}

@MainActor
final class VoiceRecognizer: ObservableObject {
    @Published var transcript: String = ""
    @Published var isListening: Bool = false
    @Published var errorMessage: String?

    private let speechRecognizer = SFSpeechRecognizer(
        locale: Locale(identifier: "en-US")
    )

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private let audioEngine = AVAudioEngine()

    private var wakePrefix = ""
    private var shouldPreserveWakePrefix = false

    var wakeWordDetector: WakeWordDetecting = SFSpeechWakeWordDetector()
    var onWakeWordDetected: (() -> Void)?

    init() {
        wakeWordDetector.onPartialTranscript = { [weak self] text in
            Task { @MainActor in
                guard let self else { return }
                self.transcript = text
            }
        }

        wakeWordDetector.onWakeWordDetected = { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.wakePrefix = self.transcript
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                self.onWakeWordDetected?()
            }
        }
    }

    func requestPermissions() async -> Bool {
        let speechAuthorized = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        guard speechAuthorized else {
            errorMessage = "Speech recognition permission denied."
            return false
        }

        let micAuthorized = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        guard micAuthorized else {
            errorMessage = "Microphone permission denied."
            return false
        }

        return true
    }

    func startWakeWordListening() {
        wakePrefix = ""
        transcript = ""
        isListening = false
        errorMessage = nil
        wakeWordDetector.start()
    }

    func stopWakeWordListening() {
        wakeWordDetector.stop()
    }

    func startListening(preservingWakePhrase: Bool = false) {
        stopWakeWordListening()
        shouldPreserveWakePrefix = preservingWakePhrase

        if !preservingWakePhrase {
            wakePrefix = ""
        }

        transcript = ""
        errorMessage = nil

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognizer is not available."
            return
        }

        do {
            try startAudioEngine()
        } catch {
            errorMessage = "Audio engine failed to start: \(error.localizedDescription)"
        }
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        isListening = false
    }

    private func startAudioEngine() throws {
        stopListening()

        try configureAudioSession()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        try setupAudioEngineTap(for: request)

        isListening = true
        errorMessage = nil
        setupInitialTranscript()

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            self?.handleRecognition(result: result, error: error)
        }
    }

    private func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func setupAudioEngineTap(for request: SFSpeechAudioBufferRecognitionRequest) throws {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    private func setupInitialTranscript() {
        if shouldPreserveWakePrefix {
            transcript = wakePrefix.trimmingCharacters(in: .whitespacesAndNewlines)
            if !transcript.isEmpty {
                transcript += " "
            }
        } else {
            transcript = ""
        }
    }

    private func handleRecognition(result: SFSpeechRecognitionResult?, error: Error?) {
        Task { @MainActor in
            if let result {
                let recognizedText = result.bestTranscription
                    .formattedString
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                let prefix = self.wakePrefix.trimmingCharacters(in: .whitespacesAndNewlines)

                if self.shouldPreserveWakePrefix, !prefix.isEmpty {
                    self.transcript = "\(prefix) \(recognizedText)"
                } else {
                    self.transcript = recognizedText
                }

                print("VoiceRecognizer received text: \(self.transcript)")

                if result.isFinal {
                    print("VoiceRecognizer finished.")
                    self.stopListening()
                }
            }

            if let error {
                print("VoiceRecognizer error: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                self.stopListening()
            }
        }
    }

    func cleanPromptForSending() -> String {
        let pattern = "(?i)\\bhey orb[iy]\\b[.,!?]*\\s*"

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let range = NSRange(location: 0, length: transcript.utf16.count)
        let cleaned = regex.stringByReplacingMatches(
            in: transcript,
            options: [],
            range: range,
            withTemplate: ""
        )

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

final class SFSpeechWakeWordDetector: WakeWordDetecting {
    var onWakeWordDetected: (() -> Void)?
    var onPartialTranscript: ((String) -> Void)?

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private let audioEngine = AVAudioEngine()
    private let wakePhrase = "hey orbi"

    func start() {
        stop()

        guard let recognizer = speechRecognizer, recognizer.isAvailable else { return }

        try? configureAudioSession()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        try? setupAudioEngineTap(for: request)

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            self?.handleWakeWordRecognition(result: result, error: error)
        }
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil
    }

    private func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func setupAudioEngineTap(for request: SFSpeechAudioBufferRecognitionRequest) throws {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    private func handleWakeWordRecognition(result: SFSpeechRecognitionResult?, error: Error?) {
        if let result {
            let text = result.bestTranscription.formattedString
            print("WakeWordDetector recognized text: \(text)")

            onPartialTranscript?(text)

            let lowerText = text.lowercased()
            if lowerText.contains(wakePhrase) || lowerText.contains("hey orby") {
                stop()

                DispatchQueue.main.async {
                    self.onWakeWordDetected?()
                }
            }
        }

        if error != nil || result?.isFinal == true {
            stop()
        }
    }
}
