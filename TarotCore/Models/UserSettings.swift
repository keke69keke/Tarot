import Foundation

// MARK: - UserSettings

/// Persistent user preferences (Requirements 6.1 – 6.5).
public struct UserSettings {

    /// Whether reversed cards can appear during a spread (Requirement 6.3).
    public var allowReversedCards: Bool = true

    /// Display language for card interpretations (Requirement 6.4).
    public var selectedLanguage: Language = .spanish

    /// Visual design of the card back used in animations (Requirement 6.1).
    public var cardBackDesign: CardBackDesign = .classic

    /// Active card deck / artwork set (Requirement 6.2).
    public var activeDeck: DeckType = .riderWaite

    /// Preferred application appearance setting.
    /// The app supports automatic, light and dark appearances.
    public var appearance: Appearance = .automatic

    /// Hour (24-hour clock) at which the daily notification fires.
    /// Valid range: 6 … 22 (Requirement 4.6).
    public var dailyNotificationHour: Int = 8

    /// Whether daily push notifications are enabled (Requirement 4.6).
    public var notificationsEnabled: Bool = false

    /// OpenAI API Key for AI chat feature (optional).
    public var openAIKey: String = ""

    /// Active tabs — Settings is fixed and cannot be removed
    public var activeTabs: [AppTab] = [.reading, .horoscope, .library, .daily, .learn, .journal, .settings, .biorhythm, .natal, .soulLink]

    /// Inactive tabs hidden from the bottom navigation menu
    public var inactiveTabs: [AppTab] = [.ask, .chat, .reference]

    /// User display name used for personalized greetings in the UI.
    public var userName: String = ""

    /// Persisted birth data for biorhythm and natal chart (luxury continuity)
    public var biorhythmBirthDate: Date? = nil
    public var natalBirthDate: Date? = nil
    public var natalBirthTime: Date? = nil
    public var natalPlace: String = ""
    
    public init(
        allowReversedCards: Bool = true,
        selectedLanguage: Language = .spanish,
        cardBackDesign: CardBackDesign = .classic,
        activeDeck: DeckType = .riderWaite,
        appearance: Appearance = .automatic,
        dailyNotificationHour: Int = 8,
        notificationsEnabled: Bool = false,
        openAIKey: String = "",
        activeTabs: [AppTab] = [.reading, .horoscope, .library, .daily, .learn, .journal, .settings, .biorhythm, .natal, .soulLink],
        inactiveTabs: [AppTab] = [.ask, .chat, .reference],
        userName: String = "",
        biorhythmBirthDate: Date? = nil,
        natalBirthDate: Date? = nil,
        natalBirthTime: Date? = nil,
        natalPlace: String = ""
    ) {
        self.allowReversedCards = allowReversedCards
        self.selectedLanguage = selectedLanguage
        self.cardBackDesign = cardBackDesign
        self.activeDeck = activeDeck
        self.appearance = appearance
        self.dailyNotificationHour = dailyNotificationHour
        self.notificationsEnabled = notificationsEnabled
        self.openAIKey = openAIKey
        self.activeTabs = activeTabs
        self.inactiveTabs = inactiveTabs
        self.userName = userName
        self.biorhythmBirthDate = biorhythmBirthDate
        self.natalBirthDate = natalBirthDate
        self.natalBirthTime = natalBirthTime
        self.natalPlace = natalPlace
    }
}

// MARK: - Appearance

/// Preferred theme for the application.
public enum Appearance: String, CaseIterable, Codable {
    case automatic
    case light
    case dark

    public var displayName: String {
        switch self {
        case .automatic: return "Automático"
        case .light: return "Claro"
        case .dark: return "Obscuro"
        }
    }
}

// MARK: - Language

/// Supported interpretation languages (Requirement 6.4).
public enum Language: String, CaseIterable, Codable {
    case spanish = "es"
    case english = "en"
 
    public var displayName: String {
        switch self {
        case .spanish: return "Español"
        case .english: return "English"
        }
    }
}

// MARK: - CardBackDesign

/// Available card-back artwork options (Requirement 6.1).
public enum CardBackDesign: String, CaseIterable, Codable {
    case classic      = "classic"
    case mystical     = "mystical"
    case celestial    = "celestial"
    case floral       = "floral"
    case alchemical   = "alchemical"
    case darkMoon     = "darkMoon"

    public var displayName: String {
        switch self {
        case .classic:    return "Clásico"
        case .mystical:   return "Místico"
        case .celestial:  return "Celestial"
        case .floral:     return "Floral Art Nouveau"
        case .alchemical: return "Alquímico"
        case .darkMoon:   return "Luna Oscura"
        }
    }

    /// Accent color used for UI indicators and glows.
    public var accentColor: (r: Double, g: Double, b: Double) {
        switch self {
        case .classic:    return (0.85, 0.72, 0.38)   // warm gold
        case .mystical:   return (0.72, 0.58, 0.92)   // purple
        case .celestial:  return (0.40, 0.72, 1.00)   // electric blue
        case .floral:     return (0.72, 0.90, 0.58)   // sage green
        case .alchemical: return (0.95, 0.75, 0.30)   // amber
        case .darkMoon:   return (0.65, 0.65, 0.75)   // silver
        }
    }
}

// MARK: - DeckType

/// Available card-front artwork decks (Requirement 6.2).
public enum DeckType: String, CaseIterable, Codable {
    case riderWaite = "riderWaite"
    case helloKitty = "helloKitty"
    case marseille  = "marseille"

    public var displayName: String {
        switch self {
        case .riderWaite: return "Rider-Waite Clásico"
        case .helloKitty: return "Hello Kitty Kawaii"
        case .marseille:  return "Tarot de Marsella"
        }
    }

    public var description: String {
        switch self {
        case .riderWaite: return "El mazo más popular del siglo XX, con ilustraciones simbólicas de Pamela Colman Smith."
        case .helloKitty: return "Una versión kawaii y adorable del Tarot para lecturas ligeras y divertidas."
        case .marseille:  return "El mazo europeo más antiguo (s. XVII), origen del Tarot moderno. Arte medieval."
        }
    }

    /// Texture style identifier used by CardTextureOverlayView
    public var textureStyle: DeckTextureStyle {
        switch self {
        case .riderWaite: return .agedParchment
        case .helloKitty: return .softPastel
        case .marseille:  return .medievalEmbroidery
        }
    }

        public var hasDedicatedArtwork: Bool {
        switch self {
        case .riderWaite, .helloKitty, .marseille: return true
        }
    }

    /// Prefix used for deck-specific image names (e.g. "helloKitty_card_00...", "marseille_card_00...").
    public var assetPrefix: String? {
        switch self {
        case .helloKitty: return "helloKitty"
        case .marseille:  return "marseille"
        case .riderWaite: return nil  // base images, no prefix
        }
    }

        /// Deck-specific color tint applied over base artwork — Marseille uses a subtle sepia
    /// wash (the dedicated woodcut-style images already carry this, tint is a mild depth layer).
    public var tintColor: (r: Double, g: Double, b: Double, opacity: Double)? {
        switch self {
        case .riderWaite: return nil
        case .helloKitty: return nil
        case .marseille:  return (0.65, 0.45, 0.20, 0.06)
        }
    }
}

/// Visual texture style for card overlays.
public enum DeckTextureStyle {
    case agedParchment
    case sacredGeometry
    case softPastel
    case medievalEmbroidery
    case watercolor
    case grunge
    case starfield
    case leafVeins
    case digitalGrid
    case papyrus
}

// MARK: - AppTab

/// Available navigation tabs in the app.
public enum AppTab: String, CaseIterable, Codable, Identifiable, Hashable {
    case reading = "reading"
    case ask = "ask"
    case horoscope = "horoscope"
    case library = "library"
    case reference = "reference"
    case daily = "daily"
    case learn = "learn"
    case journal = "journal"
    case settings = "settings"
    case chat = "chat"
    case biorhythm = "biorhythm"
    case natal = "natal"
    case soulLink = "soulLink"

    public var id: String { rawValue }
    
    public var label: String {
        switch self {
        case .reading: return "Tirada"
        case .ask: return "Preguntar"
        case .horoscope: return "Horóscopo"
        case .library: return "Biblioteca"
        case .reference: return "Referencia"
        case .daily: return "Hoy"
        case .learn: return "Aprender"
        case .journal: return "Diario"
        case .settings: return "Ajustes"
        case .chat: return "Arcana IA"
        case .biorhythm: return "Biorritmo"
        case .natal: return "Hoja Natal"
        case .soulLink: return "Almas"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .reading: return "diamond"
        case .ask: return "questionmark.circle"
        case .horoscope: return "moon"
        case .library: return "rectangle.stack"
        case .reference: return "eye"
        case .daily: return "sunrise"
        case .learn: return "lightbulb"
        case .journal: return "text.book.closed"
        case .settings: return "slider.horizontal.3"
        case .chat: return "wand.and.stars"
        case .biorhythm: return "waveform"
        case .natal: return "star.circle"
        case .soulLink: return "person.2"
        }
    }
}
