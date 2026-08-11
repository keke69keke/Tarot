import Foundation
import TarotCore
import TarotData

// MARK: - Persistence & Journaling

/// View model para guardar y gestionar lecturas de Tarot en el diario.
///
/// Conecta la capa de presentación con el `JournalRepository` real (Core Data),
/// de modo que `saveCurrentReading()` persista de verdad la lectura.
///
/// Nota: existe `TarotApp.Spread` (en `TarotApp/Core/Models/Spread.swift`) que
/// colisiona con `TarotCore.Spread`. Aquí usamos explícitamente `TarotCore.Spread`,
/// que es el modelo que espera `JournalEntry` y `JournalRepository`.
@MainActor
public struct AppTarotReadingViewModel {

    /// Repositorio de diario encargado de la persistencia.
    private let journalRepository: any JournalRepository

    /// La tirada más reciente que el usuario desea guardar (modelo de TarotCore).
    public var currentSpread: TarotCore.Spread?

    /// Notas opcionales escritas por el usuario.
    public var notes: String = ""

    public init(
        journalRepository: any JournalRepository = CoreDataJournalRepository()
    ) {
        self.journalRepository = journalRepository
    }

    /// Saves the current state of the reading to the journal.
    ///
    /// - Throws: `TarotError.persistenceFailed` si la tirada no tiene cartas
    ///           o si falla la persistencia en Core Data.
    public func saveCurrentReading() async throws {
        guard let spread = currentSpread else {
            throw TarotError.validationFailed(
                field: "tirada",
                reason: "No hay una tirada activa para guardar."
            )
        }

        guard !spread.drawnCards.isEmpty else {
            throw TarotError.validationFailed(
                field: "tirada",
                reason: "La tirada no contiene cartas dibujadas."
            )
        }

        let entry = JournalEntry(
            spread: spread,
            notes: notes
        )

        try journalRepository.save(entry: entry)
    }
}
