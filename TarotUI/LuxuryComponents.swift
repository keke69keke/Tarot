import SwiftUI

// MARK: - ARCANA Luxury Component Library
// Primitivas compartidas iOS/macOS para mantener una estética editorial coherente:
// vidrio líquido, oro lavanda, tipografía serif y animaciones lentas.

// MARK: - Adaptive Page Container
/// Centra el contenido y lo limita a un ancho cómodo de lectura.
/// Evita el "desbordamiento" visual en ventanas anchas de macOS/iPad.
struct LuxuryPage<Content: View>: View {
    var maxWidth: CGFloat = 880
    var horizontalPadding: CGFloat = 28
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .frame(maxWidth: maxWidth, alignment: .leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, horizontalPadding)
    }
}

// MARK: - Section Header
struct LuxurySectionHeader: View {
    var eyebrow: String? = nil
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let eyebrow {
                Text(eyebrow.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .tracking(2.6)
                    .foregroundStyle(Color.tarotGold.opacity(0.85))
            }
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .foregroundStyle(Color.tarotIvory.opacity(0.95))
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 11.5, weight: .light, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.48))
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Page Header
/// Cabecera de PÁGINA (el título grande de cada sección): eyebrow + título editorial 32 + subtítulo.
/// Es la plantilla de referencia de `DailyCardView`, no debe confundirse con
/// `LuxurySectionHeader`, que es para secciones internas dentro de una página.
struct LuxuryPageHeader<Trailing: View>: View {
    var eyebrow: String? = nil
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: () -> Trailing

    init(
        eyebrow: String? = nil,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let eyebrow {
                HStack(spacing: 8) {
                    EyebrowLabel(text: eyebrow)
                    Spacer(minLength: 0)
                    trailing()
                }
            }
            Text(title)
                .font(.system(size: 32, weight: .bold, design: .serif))
                .tracking(-0.8)
                .foregroundStyle(Color.tarotIvory)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.56))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.top, 12)
    }
}

extension LuxuryPageHeader where Trailing == EmptyView {
    /// Cabecera sin elemento decorativo a la derecha.
    init(eyebrow: String? = nil, title: String, subtitle: String? = nil) {
        self.init(eyebrow: eyebrow, title: title, subtitle: subtitle) { EmptyView() }
    }
}

// MARK: - Cards
/// Tarjeta de contenido con vidrio + borde dorado fino.
struct LuxuryCard<Content: View>: View {
    var cornerRadius: CGFloat = LuxuryRadius.lg
    var padding: CGFloat = 18
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .luxuryGlass(cornerRadius: cornerRadius)
    }
}

/// Panel plano con hairline, para listas y bloques densos.
struct LuxuryPanel<Content: View>: View {
    var cornerRadius: CGFloat = LuxuryRadius.md
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.045))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.tarotGold.opacity(0.16), lineWidth: 0.75)
            )
    }
}

// MARK: - Primary Button Style
/// Botón principal "oro lavanda": degradado, rim-light, brillo y feedback al pulsar.
struct LuxuryPrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.tarotIvory)
            .padding(.vertical, 16)
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.tarotGoldGradient)
                        .opacity(isEnabled ? 1 : 0.5)

                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.34), .white.opacity(0.05), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .blendMode(.overlay)

                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.55), .clear, .white.opacity(0.30)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                }
            )
            .shadow(color: Color.tarotGoldDeep.opacity(isEnabled ? 0.45 : 0.2),
                    radius: configuration.isPressed ? 8 : 18,
                    x: 0, y: configuration.isPressed ? 4 : 10)
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(.spring(response: 0.32, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

/// Botón secundario: hairline dorado sobre vidrio.
struct LuxurySecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.tarotIvory.opacity(0.92))
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.10 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.tarotGold.opacity(0.28), lineWidth: 0.8)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

/// Botón de icono circular para barras de herramientas.
struct LuxuryIconButtonStyle: ButtonStyle {
    var diameter: CGFloat = 40
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(Color.tarotIvory.opacity(0.9))
            .frame(width: diameter, height: diameter)
            .background(
                Circle().fill(Color.white.opacity(configuration.isPressed ? 0.14 : 0.06))
            )
            .overlay(Circle().stroke(Color.tarotGold.opacity(0.22), lineWidth: 0.7))
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

// MARK: - Toggle Style
/// Interruptor de alta joyería: pastilla dorada con perilla marfil.
struct LuxuryToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                configuration.isOn.toggle()
            }
            HapticManager.shared.triggerLight()
        } label: {
            HStack(spacing: 12) {
                configuration.label
                    .frame(maxWidth: .infinity, alignment: .leading)

                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule(style: .continuous)
                        .fill(
                            configuration.isOn
                                ? AnyShapeStyle(Color.tarotGoldGradient)
                                : AnyShapeStyle(Color.black.opacity(0.35))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(
                                    configuration.isOn
                                        ? Color.tarotGoldHighlight.opacity(0.7)
                                        : Color.white.opacity(0.28),
                                    lineWidth: 0.8
                                )
                        )
                        .frame(width: 46, height: 27)

                    Circle()
                        .fill(Color.tarotIvory)
                        .frame(width: 21, height: 21)
                        .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 1)
                        .padding(3)
                }
                .frame(width: 46, height: 27)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(configuration.isOn ? "1" : "0")
    }
}

// MARK: - Chip / Selector
/// Pastilla seleccionable (filtros, categorías, ajustes rápidos).
struct LuxuryChip: View {
    let title: String
    var systemImage: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 11, weight: .medium))
                }
                Text(title)
                    .font(.system(size: 12.5, weight: isSelected ? .semibold : .regular, design: .serif))
            }
            .foregroundStyle(isSelected ? Color.tarotBackground : Color.tarotIvory.opacity(0.7))
            .padding(.horizontal, 15)
            .padding(.vertical, 9)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(Color.tarotGoldGradient) : AnyShapeStyle(Color.white.opacity(0.05)))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(
                        isSelected ? Color.tarotGoldHighlight.opacity(0.8) : Color.tarotGold.opacity(0.18),
                        lineWidth: isSelected ? 0.9 : 0.7
                    )
            )
            .shadow(color: isSelected ? Color.tarotGoldDeep.opacity(0.4) : .clear, radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: isSelected)
    }
}

// MARK: - Stat / Metric
struct LuxuryMetric: View {
    let value: String
    let label: String
    var systemImage: String? = nil

    var body: some View {
        VStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Color.tarotGold.opacity(0.9))
            }
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(Color.tarotIvory)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold, design: .serif))
                .tracking(1.2)
                .foregroundStyle(Color.tarotIvory.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Decorative
/// Filete dorado con rombo central, para separar secciones con elegancia.
struct LuxuryDivider: View {
    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(LinearGradient(colors: [.clear, Color.tarotGold.opacity(0.35)], startPoint: .leading, endPoint: .trailing))
                .frame(height: 0.75)
            Image(systemName: "diamond.fill")
                .font(.system(size: 5))
                .foregroundStyle(Color.tarotGold.opacity(0.7))
            Rectangle()
                .fill(LinearGradient(colors: [Color.tarotGold.opacity(0.35), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 0.75)
        }
        .padding(.vertical, 2)
    }
}

/// Sello/etiqueta editorial en mayúsculas con tracking amplio.
struct LuxuryTag: View {
    let text: String
    var tint: Color = Color.tarotGold
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .bold, design: .serif))
            .tracking(1.4)
            .foregroundStyle(tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Capsule().fill(tint.opacity(0.12)))
            .overlay(Capsule().stroke(tint.opacity(0.3), lineWidth: 0.6))
    }
}

// MARK: - Backdrop
/// Viñeta sutil que enfoca la mirada al centro y da profundidad al fondo estelar.
struct LuxuryVignette: View {
    var body: some View {
        RadialGradient(
            colors: [.clear, Color.black.opacity(0.42)],
            center: .center,
            startRadius: 120,
            endRadius: 620
        )
        .blendMode(.multiply)
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

// MARK: - Vertical hairline
/// Línea vertical hairline para separar columnas (HStack anchos).
struct LuxuryVLine: View {
    var opacity: Double = 0.14
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, Color.tarotGold.opacity(opacity), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 0.75)
    }
}
