import Foundation

public enum TarotStrings: String {
    // Reading
    case shuffleAndReveal = "Barajar y revelar"
    case revealAll = "Revelar todas"
    case saveReading = "Guardar lectura"
    case notesPlaceholder = "Escribe tus notas..."
    
    // Daily card
    case dailyCardTitle = "Carta del día"
    case tapToReveal = "Pulsa la carta para revelarla"
    case revealedMessage = "Carta revelada. Desplázate para ver la interpretación."
    case cardFaceDown = "Carta del día boca abajo"
    
    // Journal
    case journalTitle = "Diario"
    case emptyJournalTitle = "Aún no hay lecturas guardadas"
    case emptyJournalMessage = "Guarda tus tiradas aquí y vuelve a consultarlas cuando quieras."
    
    // Settings
    case settingsTitle = "Ajustes"
    case bottomMenu = "Menú inferior"
    case personalization = "Personalización"
    case options = "Opciones"
    case allowReversed = "Permitir cartas invertidas"
    case appearance = "Apariencia"
    case theme = "Tema"
    case notifications = "Recordatorios"
    case dailyReminder = "Recordatorio diario"
    case notificationHour = "Hora de notificación: %d:00"
    case integration = "Integración"
    case openAIKey = "API Key de OpenAI"
    case openAIKeyPlaceholder = "sk-..."
    case openAIKeyConfigured = "API Key configurada"
    case openAIDescription = "Opcional. Sin API key, Arcana IA usa el motor local de tarot."
    
    // Common
    case errorTitle = "Error"
    case ok = "Aceptar"
    case retry = "Reintentar"
    case couldNotStart = "No se pudo iniciar Tarot"
    case loadError = "Error de carga de recursos"
    
    // Accessibility
    case cardBackDescription = "Carta boca abajo"
    case cardFrontDescription = "Carta %s"
    case ritualTitle = "Ritual de tarot"
    case ritualDescription = "Elige una tirada, baraja con intención y descubre lo que las cartas te quieren revelar hoy."
    case startRitual = "Iniciar ritual"
    case replaceCard = "Reemplazar carta"
    case saveEntry = "Guardar entrada"
    
    public var localized: String {
        rawValue
    }
}
