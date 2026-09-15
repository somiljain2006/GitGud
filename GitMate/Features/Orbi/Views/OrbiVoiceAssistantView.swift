//
//  OrbiVoiceAssistantView.swift
//  GitMate
//

import SwiftUI

struct OrbiVoiceAssistantView: View {
    let onPromptFinalized: (String) -> Void
    let onCancel: () -> Void
    let isProcessing: Bool
    @ObservedObject var speaker: OrbiSpeaker

    @StateObject private var recognizer = VoiceRecognizer()
    @State private var state: OrbiVoiceState = .idle
    @AppStorage("enableHeyOrbi") private var enableHeyOrbi: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 24) {
            if let error = recognizer.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            } else {
                Text(state.displayText)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
                    .animation(.easeInOut, value: state)
            }

            SiriOrbView(isActive: recognizer.isListening || isProcessing || state == .wakePhraseDetected || state == .speaking || state == .listeningForWakePhrase)
                .onTapGesture {
                    if state == .idle || state == .listeningForWakePhrase {
                        startManualListening()
                    }
                }
                .accessibilityLabel("Orbi Voice Assistant")
                .accessibilityHint("Double tap to start or stop listening")
                .accessibilityAddTraits(.isButton)

            if !recognizer.transcript.isEmpty {
                Text(recognizer.transcript)
                    .font(.body)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .padding(.horizontal, 24)
                    .frame(minHeight: 60)
                    .onChange(of: recognizer.transcript) {
                        print("OrbiVoiceAssistantView displayed transcript: \(recognizer.transcript)")
                    }
            } else {
                Spacer().frame(height: 60)
            }

            HStack(spacing: 40) {
                Button {
                    stopEverything()
                    onCancel()
                } label: {
                    Text("Cancel")
                        .fontWeight(.semibold)
                        .foregroundStyle(.red.opacity(0.8))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                }

                Button {
                    finishListeningAndSend()
                } label: {
                    Text("Send")
                        .fontWeight(.semibold)
                        .foregroundStyle(recognizer.transcript.isEmpty ? .gray : .cyan)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 24)
                        .background(Color.cyan.opacity(0.15))
                        .clipShape(Capsule())
                }
                .disabled(recognizer.transcript.isEmpty || isProcessing)
            }
        }
        .padding(32)
        .background(Color(red: 0.05, green: 0.09, blue: 0.12).opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
        .task {
            recognizer.onWakeWordDetected = {
                handleWakeWordDetected()
            }

            let authorized = await recognizer.requestPermissions()
            if authorized {
                if enableHeyOrbi {
                    startWakeWordListening()
                } else {
                    state = .idle
                }
            } else {
                state = .error("Permissions denied")
            }
        }
        .onChange(of: enableHeyOrbi) {
            if enableHeyOrbi {
                startWakeWordListening()
            } else {
                recognizer.stopWakeWordListening()
                if state == .listeningForWakePhrase {
                    state = .idle
                }
            }
        }
        .onChange(of: scenePhase) {
            if scenePhase != .active {
                stopEverything()
            } else if enableHeyOrbi && state == .idle {
                startWakeWordListening()
            }
        }
        .onChange(of: isProcessing) {
            if isProcessing {
                state = .processing
            } else if state == .processing {
                state = speaker.isSpeaking ? .speaking : .idle
            }
        }
        .onChange(of: speaker.isSpeaking) {
            if speaker.isSpeaking {
                state = .speaking
            } else if state == .speaking {
                state = .idle
                if enableHeyOrbi {
                    startWakeWordListening()
                }
            }
        }
        .onChange(of: recognizer.isListening) {
            if !recognizer.isListening && state == .listeningForPrompt && !isProcessing {
                if !recognizer.transcript.isEmpty {
                    finishListeningAndSend()
                } else {
                    state = .idle
                    if enableHeyOrbi {
                        startWakeWordListening()
                    }
                }
            }
        }
        .onDisappear {
            stopEverything()
        }
    }

    private func startWakeWordListening() {
        guard state == .idle || state == .error("") else { return }
        state = .listeningForWakePhrase
        recognizer.startWakeWordListening()
    }

    private func handleWakeWordDetected() {
        state = .wakePhraseDetected
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            startManualListening()
        }
    }

    private func startManualListening() {
        recognizer.stopWakeWordListening()
        state = .listeningForPrompt
        recognizer.startListening()
    }

    private func stopEverything() {
        recognizer.stopWakeWordListening()
        recognizer.stopListening()
        speaker.stop()
        if !isProcessing {
            state = .idle
        }
    }

    private func finishListeningAndSend() {
        let finalPrompt = recognizer.cleanPromptForSending()
        stopEverything()
        if !finalPrompt.isEmpty {
            state = .processing
            onPromptFinalized(finalPrompt)
        } else {
            state = .idle
        }
    }
}
