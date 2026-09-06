import SwiftUI
import TarotCore

// MARK: - CardRow View
struct CardRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let size: CGSize?
    let showChevron: Bool

    // Estado para efectos interactivos
    @State private var isHovering = false
    @State private var isPressed = false

    // Inicializador estándar
    init(icon: String, title: String, subtitle: String, color: Color, size: CGSize? = nil, showChevron: Bool = false) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.size = size
        self.showChevron = showChevron
    }

    var body: some View {
        HStack(spacing: DesignSystem.spacingMedium) {
            if let size {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(LinearGradient(colors: [color, color.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: size.width, height: size.height)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(.white)
                }
            } else {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: DesignSystem.iconSize.width, height: DesignSystem.iconSize.height)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .accessibilityLabel("\(title), \(subtitle)")
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }

            Spacer()

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(DesignSystem.cardPadding)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cardCornerRadius, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
.shadow(color: isPressed ? color.opacity(0.35) : Color.black.opacity(0.15), radius: isPressed ? 10 : 4, x: 0, y: isPressed ? 4 : 2)
        .scaleEffect(isHovering ? 1.02 : (isPressed ? 0.97 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: isPressed)
        .animation(.easeOut(duration: 0.15), value: isHovering)
        .onHover { isHovering in
            self.isHovering = isHovering
        }
        .onTapGesture {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                isPressed = false
            }
        }
        .accessibilityAddTraits(showChevron ? .isButton : [])
        .accessibilityHint(showChevron ? LocalizedStringKey("Tap to view details") : LocalizedStringKey(""))
    }
}
