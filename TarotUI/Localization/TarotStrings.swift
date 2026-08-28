import Foundation

public enum TarotStrings: String {
    // Reading
    case selectSpread = "Selecciona tu tirada"
    case shuffleAndReveal = "Barajar y revelar"
    case revealAll = "Revelar todas"
    case saveReading = "Guardar lectura"
    case notesPlaceholder = "Escribe tus notas..."
    case readingNotesTitle = "Notas de la lectura"
    case noSignificatorSelected = "No hay carta significadora"
    case chooseRandomly = "Elegir al azar"
    case holdToReplace = "Mantén pulsada una carta para reemplazarla"
    case reshuffle = "Re-barajar"

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
    case startReading = "Iniciar lectura"
    case retry = "Reintentar"
    case couldNotStart = "No se pudo iniciar Tarot"
    case loadError = "Error de carga de recursos"
    
    // Biorritmo
    case biorhythmTitle = "Biorritmo"
    case biorhythmEyebrow = "CICLOS  ·  RITMO NATURAL"
    case biorhythmDescription = "Cuatro curvas sutiles que siguen tu fecha de nacimiento. Léelas como mareas, no como sentencia."
    case biorhythmBirthDateLabel = "Fecha de nacimiento"
    case next30Days = "Próximos 30 días"
    case biorhythmPhysical = "Físico"
    case biorhythmEmotional = "Emocional"
    case biorhythmIntellectual = "Intelectual"
    case biorhythmIntuitive = "Intuitivo"
    case biorhythmPeak = "En pico — gran energía para actuar"
    case biorhythmHigh = "Zona alta — favorable y positivo"
    case biorhythmMedium = "Zona media — estable y equilibrado"
    case biorhythmLow = "Zona baja — prioriza el descanso"
    case biorhythmCritical = "Punto crítico — cuida tu bienestar"

    // Natal
    case natalTitle = "Hoja Natal"
    case natalEyebrow = "CARTA  ·  CIELO NATAL"
    case natalDescription = "Tres puntos esenciales — Sol, Luna y Ascendente — con fecha, hora y lugar."
    case natalBirthData = "Datos de nacimiento"
    case natalDateLabel = "Fecha"
    case natalTimeLabel = "Hora (aprox.)"
    case natalPlacePlaceholder = "Lugar (opcional)"
    case natalWheelTitle = "Tu Rueda del Zodíaco"
    case natalSun = "Sol"
    case natalMoon = "Luna"
    case natalAscendant = "Ascendente"
    case natalSunDetail = "Tu esencia, identidad y propósito central."
    case natalMoonDetail = "Tu mundo emocional e intuición (aproximado)."
    case natalAscDetail = "Tu imagen externa al conocer (aproximado)."
    case natalElementPrefix = "Elemento: %s · %s"

    // Reading extras
    case chooseFirstTwo = "Elegir las 2 primeras cartas"
    case chooseFirstTwoDesc = "Opcional. Define qué sale en posición 1 y 2."
    case removeChosen = "Quitar cartas elegidas"
    case addCard = "AÑADIR"
    case choose = "Elegir"
    case significatorTitle = "Carta significadora"
    case significatorSubtitle = "Tu carta"
    case numberOfCards = "Número de cartas"
    case shuffling = "Barajando…"
    case cardRevealedShort = "Carta revelada"
    case tapToRevealShort = "Toca para revelar"
    case searchCard = "Buscar carta"
    case chooseReplacement = "Elegir carta de reemplazo"
    case cancel = "Cancelar"

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
