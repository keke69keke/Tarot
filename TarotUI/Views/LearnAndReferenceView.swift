import SwiftUI
import TarotDI

/// «Aprender» y «Referencia» eran dos entradas del menú que se pisaban: una es el
/// curso con lecciones y la otra la biblioteca de consulta (libros, guía, símbolos).
/// Ahora son una sola pantalla con dos solapas, para no partir en dos lo que se usa
/// junto: el curso te manda a la referencia y la referencia te devuelve al curso.
public struct LearnAndReferenceView: View {
    public enum Solapa: String, CaseIterable {
        case aprender = "Aprender"
        case referencia = "Referencia"
    }

    let container: AppContainer
    @State private var solapa: Solapa

    public init(container: AppContainer, inicial: Solapa = .aprender) {
        self.container = container
        _solapa = State(initialValue: inicial)
    }

    public var body: some View {
        VStack(spacing: 0) {
            Picker("Sección", selection: $solapa) {
                ForEach(Solapa.allCases, id: \.self) { opcion in
                    Text(opcion.rawValue).tag(opcion)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 4)

            switch solapa {
            case .aprender:
                LearningCenterView(onOpenReference: {
                    withAnimation(.easeInOut(duration: 0.25)) { solapa = .referencia }
                })
            case .referencia:
                ReferenceView(container: container)
            }
        }
    }
}
