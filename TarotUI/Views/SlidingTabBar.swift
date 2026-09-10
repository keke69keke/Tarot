import SwiftUI
import TarotCore

/// Camera-style mode switcher bottom navigation.
/// Refined as "Liquid Glass" — translucent, organic, and high-end.
struct SlidingTabBar: View {
    @Binding var selectedTab: AppTab
    let activeTabs: [AppTab]
    @Namespace private var pillNamespace

    var body: some View {
        HStack {
            Spacer()
            
            // The main mode-switcher capsule
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(activeTabs) { tab in
                        TabBarButton(
                            tab: tab,
                            isSelected: selectedTab == tab,
                            pillNamespace: pillNamespace
                        ) {
                            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = tab
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .frame(maxWidth: 340)
            .luxuryGlass(cornerRadius: LuxuryRadius.pill)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
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
            Text(tab.label.uppercased())
                .font(.system(size: 11, weight: .medium, design: .serif))
                .tracking(1.2)
                .foregroundStyle(isSelected ? Color.tarotGold : Color.tarotIvory.opacity(0.5))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .fixedSize(horizontal: true, vertical: false)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color.tarotGold.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(Color.tarotGold.opacity(0.3), lineWidth: 0.5)
                            )
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
