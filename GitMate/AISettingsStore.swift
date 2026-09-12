//
//  AISettingsStore.swift
//  GitMate
//
//  Created by somil jain on 12/09/26.
//

import Foundation
import Security

final class AISettingsStore {
    static let shared = AISettingsStore()

    private init() {}

    private let modelKey = "gitmate.ai.model"
    private let baseURLKey = "gitmate.ai.baseURL"

    private let keychainService = "com.gitmate.ai"
    private let keychainAccount = "apiKey"

    var settings: AISettings {
        get {
            AISettings(
                model: UserDefaults.standard.string(
                    forKey: modelKey
                ) ?? AISettings.default.model,

                apiKey: readAPIKey(),

                baseURL: UserDefaults.standard.string(
                    forKey: baseURLKey
                ) ?? AISettings.default.baseURL
            )
        }

        set {
            UserDefaults.standard.set(
                newValue.model,
                forKey: modelKey
            )

            UserDefaults.standard.set(
                newValue.baseURL,
                forKey: baseURLKey
            )

            saveAPIKey(newValue.apiKey)
        }
    }

    private func saveAPIKey(_ apiKey: String) {
        let data = Data(apiKey.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
        ]

        SecItemDelete(query as CFDictionary)

        guard !apiKey.isEmpty else {
            return
        }

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data,
        ]

        SecItemAdd(
            attributes as CFDictionary,
            nil
        )
    }

    private func readAPIKey() -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?

        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )

        guard status == errSecSuccess,
              let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8)
        else {
            return ""
        }

        return apiKey
    }
}
