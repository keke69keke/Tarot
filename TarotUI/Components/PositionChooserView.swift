import SwiftUI
import TarotCore

struct PositionChooserView: View {
    @Binding var query: String
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var positions: [SpreadPosition] {
        SpreadType.allCases.filter { $0 != .free }.flatMap { $0.positions }
    }

    var filtered: [SpreadPosition] {
        guard !query.isEmpty else { return positions }
        return positions.filter { $0.displayName.localizedStandardContains(query) }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { position in
                Button {
                    onSelect(position.displayName)
                    dismiss()
                } label: {
                    Text(position.displayName)
                }
            }
            .searchable(text: $query)
            .navigationTitle("Selecciona la posición")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}
