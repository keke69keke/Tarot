import Foundation

/// Errors that can arise when interacting with the OpenAI chat API.
public enum ChatError: LocalizedError {
    case invalidAPIKey
    case rateLimited
    case serverError(Int)
    case parseError
    case appleModelUnavailable(String)

    public var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "API Key inválida. Ve a Ajustes y verifica tu clave de OpenAI."
        case .rateLimited:
            return "Demasiadas consultas. Espera un momento antes de continuar."
        case .serverError(let code):
            return "Error del servidor (\(code)). Intenta de nuevo."
        case .parseError:
            return "Error al procesar la respuesta. Intenta de nuevo."
        case .appleModelUnavailable(let reason):
            return "IA nativa de Apple no disponible: \(reason)."
        }
    }
}
