import SwiftUI
import TarotCore

/// Bottom navigation — "Liquid Glass" capsule.
/// The selected tab expands to show its label; the rest stay as quiet glyphs.
struct SlidingTabBar: View {
    @Binding var selectedTab: AppTab
    let activeTabs: [AppTab]
    @Namespace private var pillNamespace

    var body: some View {
        HStack {
            Spacer(minLength: 0)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(activeTabs) { tab in
                            TabBarButton(
                                tab: tab,
                                isSelected: selectedTab == tab,
                                pillNamespace: pillNamespace
                            ) {
                                withAnimation(.interactiveSpring(response: 0.34, dampingFraction: 0.72)) {
                                    selectedTab = tab
                                }
                                HapticManager.shared.triggerLight()
                            }
                            .id(tab)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                }
                .onChange(of: selectedTab) { newTab in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(newTab, anchor: .center)
                    }
                }
            }
            .frame(maxWidth: 520)
            .liquidGlassSurface(cornerRadius: LuxuryRadius.pill)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 20)
    }
}

// MARK: - Individual Tab Button

struct TabBarButton: View {
    let tab: AppTab
    let isSelected: Bool
    let pillNamespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))

                if isSelected {
                    Text(tab.label.uppercased())
                        .font(.system(size: 10.5, weight: .semibold, design: .serif))
                        .tracking(1.0)
                        .fixedSize()
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .leading)))
                }
            }
            .foregroundStyle(isSelected ? Color.tarotGold : Color.tarotIvory.opacity(0.55))
            .padding(.horizontal, isSelected ? 14 : 12)
            .padding(.vertical, 9)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(Color.tarotGold.opacity(0.16))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.tarotGold.opacity(0.34), lineWidth: 0.7)
                        )
                        .shadow(color: Color.tarotGoldDeep.opacity(0.25), radius: 8, x: 0, y: 3)
                        .matchedGeometryEffect(id: "tabPill", in: pillNamespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
