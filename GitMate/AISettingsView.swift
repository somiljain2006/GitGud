//
//  AISettingsView.swift
//  GitMate
//
//  Created by somil jain on 12/09/26.
//

import SwiftUI

struct AISettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var model = ""
    @State private var apiKey = ""
    @State private var baseURL = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Model") {
                    TextField(
                        "Model name",
                        text: $model
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                }

                Section("API Key") {
                    SecureField(
                        "Enter API key",
                        text: $apiKey
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                }

                Section("Base URL") {
                    TextField(
                        "API base URL",
                        text: $baseURL
                    )
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                }

                Section {
                    Button("Save Settings") {
                        saveSettings()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("AI Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .topBarLeading
                ) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadSettings()
            }
        }
    }

    private func loadSettings() {
        let settings = AISettingsStore.shared.settings

        model = settings.model
        apiKey = settings.apiKey
        baseURL = settings.baseURL
    }

    private func saveSettings() {
        let cleanedBaseURL = baseURL
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        let newSettings = AISettings(
            model: model.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
            apiKey: apiKey.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
            baseURL: cleanedBaseURL
        )

        AISettingsStore.shared.settings = newSettings

        dismiss()
    }
}

#Preview {
    AISettingsView()
}
