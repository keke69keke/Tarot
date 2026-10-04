import SwiftUI

/// Rueda del zodiaco con las lineas de aspecto del signo elegido.
///
/// Las lineas se trazan de verdad: cada aspecto sale del centro del signo
/// marcado hacia los signos que forman sextil (60°), cuadratura (90°),
/// trino (120°) u oposicion (180°) con el. Al cambiar de signo se vuelven a
/// trazar progresivamente, que es lo que da la sensacion de que la rueda "lee".
struct AspectWheelView: View {
    let destacado: ZodiacSign?
    var diameter: CGFloat = 300

    @State private var trazado: Double = 0

    static let orden: [ZodiacSign] = [
        .aries, .taurus, .gemini, .cancer, .leo, .virgo,
        .libra, .scorpio, .sagittarius, .capricorn, .aquarius, .pisces
    ]

    private struct Aspecto {
        let nombre: String
        let pasos: Int
        let color: Color
        let guiones: [CGFloat]
    }

    private static let aspectos: [Aspecto] = [
        Aspecto(nombre: "Sextil", pasos: 2, color: Color.tarotIvory.opacity(0.34), guiones: [3, 4]),
        Aspecto(nombre: "Cuadratura", pasos: 3, color: Color.orange.opacity(0.42), guiones: [6, 3]),
        Aspecto(nombre: "Trino", pasos: 4, color: Color.tarotGold.opacity(0.58), guiones: []),
        Aspecto(nombre: "Oposicion", pasos: 6, color: Color.purple.opacity(0.5), guiones: [1.5, 3])
    ]

    var body: some View {
        Canvas { contexto, tamano in
            let centro = CGPoint(x: tamano.width / 2, y: tamano.height / 2)
            let radio = min(tamano.width, tamano.height) / 2 - 14
            let interior = radio * 0.80
            let rebanada = 2 * Double.pi / 12

            func punto(_ indice: Int, radio r: CGFloat) -> CGPoint {
                let angulo = -Double.pi / 2 + (Double(indice) + 0.5) * rebanada
                return CGPoint(x: centro.x + r * CGFloat(cos(angulo)), y: centro.y + r * CGFloat(sin(angulo)))
            }

            // Doce casas: la del signo elegido se enciende en oro.
            for (i, signo) in Self.orden.enumerated() {
                let inicio = -Double.pi / 2 + Double(i) * rebanada
                let fin = inicio + rebanada
                var casa = Path()
                casa.move(to: CGPoint(x: centro.x + interior * CGFloat(cos(inicio)), y: centro.y + interior * CGFloat(sin(inicio))))
                casa.addArc(center: centro, radius: interior, startAngle: .radians(inicio), endAngle: .radians(fin), clockwise: false)
                casa.addLine(to: CGPoint(x: centro.x + radio * CGFloat(cos(fin)), y: centro.y + radio * CGFloat(sin(fin))))
                casa.addArc(center: centro, radius: radio, startAngle: .radians(fin), endAngle: .radians(inicio), clockwise: true)
                casa.closeSubpath()

                let activa = signo == destacado
                contexto.fill(casa, with: .color(activa ? Color.tarotGold.opacity(0.26) : Color.white.opacity(0.05)))
                contexto.stroke(casa, with: .color(activa ? Color.tarotGold.opacity(0.8) : Color.white.opacity(0.16)), lineWidth: 1.1)

                let etiqueta = punto(i, radio: (radio + interior) / 2)
                var glifo = contexto.resolve(Text(signo.symbol).font(.system(size: 15, weight: activa ? .bold : .regular)))
                glifo.shading = .color(activa ? Color.tarotGold : Color.tarotIvory.opacity(0.75))
                contexto.draw(glifo, at: etiqueta)
            }

            // Círculo interior, el lugar donde vive la lectura.
            var circulo = Path()
            circulo.addEllipse(in: CGRect(x: centro.x - interior, y: centro.y - interior, width: interior * 2, height: interior * 2))
            contexto.stroke(circulo, with: .color(Color.tarotGold.opacity(0.22)), lineWidth: 0.9)

            // Lineas de aspecto desde el signo elegido.
            guard let elegido = destacado, let indice = Self.orden.firstIndex(of: elegido) else { return }
            for aspecto in Self.aspectos {
                let destino = (indice + aspecto.pasos) % 12
                let desde = punto(indice, radio: interior * 0.97)
                let hasta = punto(destino, radio: interior * 0.97)
                let corte = CGPoint(
                    x: desde.x + (hasta.x - desde.x) * CGFloat(trazado),
                    y: desde.y + (hasta.y - desde.y) * CGFloat(trazado)
                )
                var linea = Path()
                linea.move(to: desde)
                linea.addLine(to: corte)
                contexto.stroke(
                    linea,
                    with: .color(aspecto.color),
                    style: StrokeStyle(lineWidth: aspecto.pasos == 4 ? 1.5 : 1.1, lineCap: .round, dash: aspecto.guiones)
                )
            }
        }
        .frame(width: diameter, height: diameter)
        .onAppear { trazar() }
        .onChange(of: destacado) { _ in trazar() }
        .accessibilityLabel("Rueda del zodiaco con las lineas de aspecto de tu signo")
    }

    /// Traza (o vuelve a trazar) las lineas con una animacion corta.
    private func trazar() {
        trazado = 0
        withAnimation(.easeOut(duration: 0.85)) { trazado = 1 }
    }
}

/// Leyenda de los aspectos, para que las lineas no sean un misterio.
struct AspectLegendView: View {
    private let filas: [(nombre: String, grados: String, color: Color)] = [
        ("Trino", "120° — fluidez", Color.tarotGold),
        ("Sextil", "60° — oportunidad", Color.tarotIvory.opacity(0.7)),
        ("Cuadratura", "90° — tensión", Color.orange),
        ("Oposición", "180° — espejo", Color.purple)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(Array(filas.enumerated()), id: \.offset) { _, fila in
                HStack(spacing: 10) {
                    Capsule()
                        .fill(fila.color.opacity(0.7))
                        .frame(width: 22, height: 2)
                    Text(fila.nombre)
                        .font(.system(size: 12, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.tarotIvory.opacity(0.9))
                    Text(fila.grados)
                        .font(.system(size: 12, design: .serif))
                        .foregroundStyle(Color.tarotIvory.opacity(0.55))
                }
            }
        }
    }
}
