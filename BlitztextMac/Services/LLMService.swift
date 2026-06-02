import Foundation

enum LLMError: LocalizedError {
    case networkError(String)
    case apiError(String)
    case noContent

    var errorDescription: String? {
        switch self {
        case .networkError(let msg):
            return "Ollama nicht erreichbar: \(msg)"
        case .apiError(let msg):
            return "Fehler von Ollama: \(msg)"
        case .noContent:
            return "Keine Antwort erhalten. Bitte nochmal versuchen."
        }
    }
}

private let ollamaModel = "qwen3.5:latest"

private struct OllamaChatRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    struct Options: Encodable {
        let temperature: Double
    }

    let model: String
    let messages: [Message]
    let think: Bool
    let stream: Bool
    let options: Options
}

private struct OllamaChatResponse: Decodable {
    struct Message: Decodable {
        let content: String?
    }

    let message: Message?
}

enum LLMService {
    private static let chatURL = URL(string: "http://localhost:11434/api/chat")!

    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.waitsForConnectivity = false
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 60
        return URLSession(configuration: configuration)
    }()

    static func improve(
        text: String,
        settings: TextImprovementSettings
    ) async throws -> String {
        try await complete(
            text: text,
            systemPrompt: buildSystemPrompt(settings: settings),
            temperature: 0.3
        )
    }

    static func dampfAblassen(
        text: String,
        systemPrompt: String
    ) async throws -> String {
        try await complete(
            text: text,
            systemPrompt: systemPrompt,
            temperature: 0.4
        )
    }

    static func addEmojis(
        text: String,
        settings: EmojiTextSettings
    ) async throws -> String {
        try await complete(
            text: text,
            systemPrompt: buildEmojiSystemPrompt(density: settings.emojiDensity),
            temperature: 0.3
        )
    }

    private static func complete(
        text: String,
        systemPrompt: String,
        temperature: Double
    ) async throws -> String {
        let payload = OllamaChatRequest(
            model: ollamaModel,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: text),
            ],
            think: false,
            stream: false,
            options: .init(temperature: temperature)
        )

        var request = URLRequest(url: chatURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.networkError("Keine gültige Antwort")
        }

        guard httpResponse.statusCode == 200 else {
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["error"]
            throw LLMError.apiError(msg ?? "Status \(httpResponse.statusCode)")
        }

        let result = try JSONDecoder().decode(OllamaChatResponse.self, from: data)
        guard let content = result.message?.content,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LLMError.noContent
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func buildEmojiSystemPrompt(density: EmojiTextSettings.EmojiDensity) -> String {
        let densityInstruction: String
        switch density {
        case .wenig:
            densityInstruction = "Setze nur vereinzelt Emojis ein, maximal 1-2 pro Absatz."
        case .mittel:
            densityInstruction = "Setze regelmaessig passende Emojis ein, etwa alle 1-2 Saetze."
        case .viel:
            densityInstruction = "Setze grosszuegig Emojis ein, gerne mehrere pro Satz."
        }

        return "Du erhaeltst ein gesprochenes Transkript. Gib den Text moeglichst originalgetreu zurueck, aber fuege passende Emojis ein. \(densityInstruction) Korrigiere offensichtliche Sprach- und Grammatikfehler. Behalte den Stil und die Bedeutung bei. Gib NUR den Text mit Emojis zurueck, keine Erklaerungen."
    }

    private static func buildSystemPrompt(settings: TextImprovementSettings) -> String {
        if !settings.systemPrompt.isEmpty {
            var prompt = settings.systemPrompt
            if !settings.customTerms.isEmpty {
                prompt += "\n\nWichtig: Diese Eigennamen und Fachbegriffe muessen exakt so geschrieben werden: \(settings.customTerms.joined(separator: ", "))"
            }
            return prompt
        }

        var prompt = """
        Du bist ein Lektor und Schreibassistent. Verbessere den folgenden Text:
        - Korrigiere Rechtschreibung und Grammatik
        - Verbessere die Formulierung und den Lesefluss
        - Behalte die urspruengliche Bedeutung bei
        - Gib NUR den verbesserten Text zurueck, keine Erklaerungen
        """

        switch settings.tone {
        case .formal:
            prompt += "\n- Verwende einen formellen, professionellen Ton"
        case .neutral:
            prompt += "\n- Verwende einen neutralen, klaren Ton"
        case .casual:
            prompt += "\n- Verwende einen lockeren, natuerlichen Ton"
        }

        if !settings.customTerms.isEmpty {
            prompt += "\n\nWichtig: Diese Eigennamen und Fachbegriffe muessen exakt so geschrieben werden: \(settings.customTerms.joined(separator: ", "))"
        }

        if !settings.context.isEmpty {
            prompt += "\n\nKontext: \(settings.context)"
        }

        return prompt
    }
}
