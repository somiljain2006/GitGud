//
//  SessionStore.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import Foundation
import Combine

@MainActor
final class SessionStore: ObservableObject {
    @Published var isLoggedIn: Bool {
        didSet { UserDefaults.standard.set(isLoggedIn, forKey: Keys.isLoggedIn) }
    }

    @Published var savedEmail: String {
        didSet { UserDefaults.standard.set(savedEmail, forKey: Keys.savedEmail) }
    }

    private(set) var savedAccessKey: String?

    init() {
        self.isLoggedIn = UserDefaults.standard.bool(forKey: Keys.isLoggedIn)
        self.savedEmail = UserDefaults.standard.string(forKey: Keys.savedEmail) ?? ""
        self.savedAccessKey = KeychainHelper.read(service: Keys.service, account: Keys.accessKey)
    }

    func signIn(email: String, accessKey: String) {
        savedEmail = email
        self.savedAccessKey = accessKey

        // Always securely store the access key on sign in
        KeychainHelper.save(accessKey, service: Keys.service, account: Keys.accessKey)

        isLoggedIn = true
    }

    func signOut() {
        isLoggedIn = false
        // Delete the secure token, but keep the email for easier re-login
        KeychainHelper.delete(service: Keys.service, account: Keys.accessKey)
        savedAccessKey = nil
    }

    private enum Keys {
        static let isLoggedIn = "gitgud.isLoggedIn"
        static let savedEmail = "gitgud.savedEmail"
        static let service = "gitgud.auth"
        static let accessKey = "gitgud.accessKey"
    }
}

enum KeychainHelper {
    static func save(_ value: String, service: String, account: String) {
        let data = Data(value.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func read(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)
    }
}
