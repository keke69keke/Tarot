import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Turn

/// Un turno de conversación para los motores de Arcana.
public struct ArcanaChatTurn: Sendable, Equatable {
    public let role: String   // "user" | "assistant"
    public let content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

// MARK: - Resultado

/// Respuesta generada + motor que la produjo (para diagnóstico y UI).
public struct ArcanaGeneration: Sendable {
    public let text: String
    public let engine: String
    public init(text: String, engine: String) {
        self.text = text
        self.engine = engine
    }
}

// MARK: - Motor Apple Intelligence (on-device)

/// Acceso a la IA nativa de Apple (Apple Intelligence / Foundation Models).
/// Disponible en iOS 26+ / macOS 26+ cuando el dispositivo tiene Apple
/// Intelligence activado; en equipos antiguos compila igual pero reporta
/// `isAvailable == false` y el router cae al siguiente motor.
public enum AppleArcanaModel {

    public static let engineName = "Apple Intelligence"

    #if canImport(FoundationModels)

    /// true si el modelo del sistema está listo para usar en este dispositivo.
    @available(iOS 26.0, macOS 26.0, *)
    public static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    /// Motivo de indisponibilidad (para UI/diagnóstico). nil si está disponible.
    @available(iOS 26.0, macOS 26.0, *)
    public static var unavailableReason: String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(.deviceNotEligible):
            return "equipo no compatible"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Apple Intelligence no está activado"
        case .unavailable(.modelNotReady):
            return "el modelo aún se está descargando"
        @unknown default:
            return "no disponible"
        }
    }

    @available(iOS 26.0, macOS 26.0, *)
    public static func generate(
        systemPrompt: String,
        history: [ArcanaChatTurn],
        userMessage: String
    ) async throws -> String {
        guard isAvailable else {
            throw ChatError.appleModelUnavailable(unavailableReason ?? "no disponible")
        }

        let conversation = history.map { turn -> String in
            let speaker = (turn.role == "user") ? "Consultante" : "Arcana"
            return "\(speaker): \(turn.content)"
        }.joined(separator: "\n\n")

        let prompt: String
        if conversation.isEmpty {
            prompt = userMessage
        } else {
            prompt = """
            Conversación previa:
            \(conversation)

            Consultante: \(userMessage)
            """
        }

        // Sesión con las instrucciones del personaje; el modelo del sistema
        // mantiene el contexto de la propia sesión en cada llamada.
        let session = LanguageModelSession(instructions: systemPrompt)
        let response = try await session.respond(to: prompt)
        return response.content
    }

    #endif
}

// MARK: - Router (Apple → OpenAI → local)

/// Coordina el orden de motores del chatbot "por debajo de la app":
/// 1. Apple Intelligence (on-device, sin API key, privado).
/// 2. OpenAI (si hay clave configurada) — lo invoca el llamador.
/// 3. Respuesta local determinista — la invoca el llamador.
public enum ArcanaIntelligenceRouter {

    /// Indica si Apple Intelligence puede responder en este dispositivo.
    public static var appleAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            return AppleArcanaModel.isAvailable
        }
        return false
        #else
        return false
        #endif
    }

    /// Nombre del motor preferente actual (para mostrar en la UI).
    public static var preferredEngineName: String {
        appleAvailable ? AppleArcanaModel.engineName : "OpenAI"
    }

    /// Intenta generar con Apple Intelligence. Devuelve nil si el motor no
    /// está disponible o falla (el llamador debe continuar con OpenAI/local).
    public static func tryApple(
        systemPrompt: String,
        history: [ArcanaChatTurn],
        userMessage: String
    ) async -> ArcanaGeneration? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            do {
                let text = try await AppleArcanaModel.generate(
                    systemPrompt: systemPrompt,
                    history: history,
                    userMessage: userMessage
                )
                return ArcanaGeneration(text: text, engine: AppleArcanaModel.engineName)
            } catch {
                return nil
            }
        }
        return nil
        #else
        return nil
        #endif
    }
}
