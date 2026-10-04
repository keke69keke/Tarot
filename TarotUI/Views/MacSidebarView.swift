import SwiftUI
import TarotCore

/// Luxury Navigation Sidebar for macOS.
/// A vertical rail grouped by intention (Lectura / Estudio / Personal),
/// with hover affordances and a branded header — keeping the "100k MXN" aesthetic.
struct MacSidebarView: View {
    @Binding var selectedTab: AppTab
    let activeTabs: [AppTab]
    @Namespace private var pillNamespace

    @State private var hoveredTab: AppTab?

    /// Grouping gives the rail a magazine-table-of-contents rhythm instead of a flat list.
    private var sections: [(title: String, tabs: [AppTab])] {
        let groups: [(String, [AppTab])] = [
            ("Lectura", [.reading, .ask, .daily, .chat]),
            ("Estudio", [.horoscope, .library, .learn, .lunar, .natal, .biorhythm]),
            ("Personal", [.journal, .soulLink])
        ]
        return groups.compactMap { title, tabs in
            let present = tabs.filter { activeTabs.contains($0) }
            return present.isEmpty ? nil : (title, present)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    ForEach(sections, id: \.title) { section in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.title.uppercased())
                                .font(.system(size: 9, weight: .bold, design: .serif))
                                .tracking(2.0)
                                .foregroundStyle(Color.tarotIvory.opacity(0.45))
                                .padding(.horizontal, 14)
                                .padding(.bottom, 2)

                            ForEach(section.tabs) { tab in
                                SidebarItem(
                                    tab: tab,
                                    isSelected: selectedTab == tab,
                                    isHovered: hoveredTab == tab,
                                    pillNamespace: pillNamespace
                                ) {
                                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                                        selectedTab = tab
                                    }
                                }
                                .onHover { hovering in
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        hoveredTab = hovering ? tab : (hoveredTab == tab ? nil : hoveredTab)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 10)
            }

            footer
        }
        .frame(width: 244)
        .liquidGlassSurface(cornerRadius: 0)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.tarotGold.opacity(0.18), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 0.75)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 11) {
                ZStack {
                    Circle()
                        .fill(Color.tarotGoldGradient)
                        .frame(width: 32, height: 32)
                        .shadow(color: Color.tarotGoldDeep.opacity(0.5), radius: 8, x: 0, y: 3)
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.tarotBackground)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("ARCANA")
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .tracking(3.2)
                        .foregroundStyle(Color.tarotIvory)
                    Text("Tarot Studio")
                        .font(.system(size: 9.5, weight: .medium, design: .serif))
                        .tracking(1.6)
                        .foregroundStyle(Color.tarotGold.opacity(0.72))
                }
            }
        }
        .padding(.horizontal, LuxurySpacing.lg)
        .padding(.top, 26)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .bottom) {
            Rectangle()
                .fill(Color.tarotGold.opacity(0.14))
                .frame(height: 0.75)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Rectangle()
                .fill(Color.tarotGold.opacity(0.14))
                .frame(height: 0.75)

            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                    selectedTab = .settings
                }
            } label: {
                HStack(spacing: 11) {
                    Image(systemName: AppTab.settings.systemImage)
                        .font(.system(size: 14, weight: .light))
                        .frame(width: 22)
                    Text(AppTab.settings.label)
                        .font(.system(size: 13.5, weight: selectedTab == .settings ? .semibold : .medium, design: .serif))
                    Spacer()
                }
                .foregroundStyle(selectedTab == .settings ? Color.tarotGold : Color.tarotIvory.opacity(0.6))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(selectedTab == .settings ? Color.tarotGold.opacity(0.14) : Color.clear)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 10)

            Text("v1.0 · Editorial Edition")
                .font(.system(size: 9, weight: .medium, design: .serif))
                .tracking(0.6)
                .foregroundStyle(Color.tarotIvory.opacity(0.42))
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .padding(.top, 10)
    }
}

struct SidebarItem: View {
    let tab: AppTab
    let isSelected: Bool
    var isHovered: Bool = false
    let pillNamespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Filo dorado del elemento activo
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(Color.tarotGoldGradient) : AnyShapeStyle(Color.clear))
                    .frame(width: 2.5, height: 18)

                Image(systemName: tab.systemImage)
                    .font(.system(size: 15, weight: isSelected ? .regular : .light))
                    .frame(width: 22, height: 22)
                    .foregroundStyle(isSelected ? Color.tarotGold : Color.tarotIvory.opacity(isHovered ? 0.85 : 0.5))

                Text(tab.label)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium, design: .serif))
                    .foregroundStyle(isSelected ? Color.tarotIvory : Color.tarotIvory.opacity(isHovered ? 0.85 : 0.72))

                Spacer(minLength: 0)
            }
            .padding(.trailing, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(Color.tarotGold.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(Color.tarotGold.opacity(0.30), lineWidth: 0.9)
                        )
                        .shadow(color: Color.tarotGoldDeep.opacity(0.28), radius: 8, x: 0, y: 3)
                        .matchedGeometryEffect(id: "sidebarPill", in: pillNamespace)
                } else if isHovered {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
