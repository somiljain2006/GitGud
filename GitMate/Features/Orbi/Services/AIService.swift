//
//  AIService.swift
//  GitMate
//
//  Created by somil jain on 12/09/26.
//

import Foundation

enum AIServiceError: LocalizedError {
    case missingSettings
    case invalidURL
    case invalidResponse
    case apiError(String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .missingSettings:
            return "Please add your model, API key, and base URL in AI Settings."

        case .invalidURL:
            return "The API base URL is invalid."

        case .invalidResponse:
            return "The AI service returned an invalid response."

        case let .apiError(message):
            return message

        case .emptyResponse:
            return "The AI returned an empty response."
        }
    }
}

final class AIService {
    static let shared = AIService()

    private init() {}

    func sendMessage(
        _ message: String,
        systemPrompt: String? = nil,
        conversation: [AIChatMessage] = []
    ) async throws -> String {
        let settings = AISettingsStore.shared.settings

        guard !settings.model.isEmpty,
              !settings.apiKey.isEmpty,
              !settings.baseURL.isEmpty
        else {
            throw AIServiceError.missingSettings
        }

        let request = try makeRequest(
            baseURL: settings.baseURL,
            apiKey: settings.apiKey,
            model: settings.model,
            message: message,
            systemPrompt: systemPrompt,
            conversation: conversation
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        return try decodeResponse(data: data, response: response)
    }

    private func makeRequest(
        baseURL: String,
        apiKey: String,
        model: String,
        message: String,
        systemPrompt: String? = nil,
        conversation: [AIChatMessage]
    ) throws -> URLRequest {
        let cleanURL = baseURL
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        guard let url = URL(string: "\(cleanURL)/chat/completions") else {
            throw AIServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var allMessages: [ChatCompletionMessage] = []

        if let systemPrompt {
            allMessages.append(
                ChatCompletionMessage(role: "system", content: systemPrompt)
            )
        }

        allMessages += conversation.map {
            ChatCompletionMessage(
                role: $0.role == .user ? "user" : "assistant",
                content: $0.content
            )
        }

        allMessages.append(
            ChatCompletionMessage(role: "user", content: message)
        )

        let requestBody = ChatCompletionRequest(
            model: model,
            messages: allMessages,
            temperature: 0.7
        )

        request.httpBody = try JSONEncoder().encode(requestBody)
        return request
    }

    private func decodeResponse(data: Data, response: URLResponse) throws -> String {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "The API request failed."
            throw AIServiceError.apiError(errorMessage)
        }

        let decodedResponse = try JSONDecoder().decode(
            ChatCompletionResponse.self,
            from: data
        )

        guard let content = decodedResponse.choices.first?.message.content,
              !content.isEmpty
        else {
            throw AIServiceError.emptyResponse
        }

        return content
    }
}

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatCompletionMessage]
    let temperature: Double
}

private struct ChatCompletionMessage: Codable {
    let role: String
    let content: String
}

private struct ChatCompletionResponse: Decodable {
    let choices: [ChatCompletionChoice]
}

private struct ChatCompletionChoice: Decodable {
    let message: ChatCompletionMessage
}
