import SwiftUI
import TarotCore

/// Luxury Navigation Sidebar for macOS.
/// A vertical rail that adapts to the user's active tabs, maintaining the "100k MXN" aesthetic.
struct MacSidebarView: View {
    @Binding var selectedTab: AppTab
    let activeTabs: [AppTab]
    @Namespace private var pillNamespace

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header / Logo Section
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(Color.tarotGold)
                Text("ARCANA")
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .tracking(3)
                    .foregroundStyle(Color.tarotIvory)
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .background(Color.tarotGold.opacity(0.2))
                .padding(.horizontal)

            Spacer()

            // Navigation Items
            VStack(alignment: .leading, spacing: 8) {
                ForEach(activeTabs) { tab in
                    SidebarItem(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        pillNamespace: pillNamespace
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 12)

            Spacer()

            // Bottom Section
            VStack(alignment: .leading, spacing: 12) {
                // We provide a simple button here; the actual action is handled in ContentView via selectedTab
            }
            .padding(.bottom, 30)
            .padding(.horizontal, 12)
        }
        .frame(width: 260)
        .background(Color.tarotBackground.opacity(0.6))
        .luxuryGlass(cornerRadius: 0) // Sidebar is usually flush to the edge
        .overlay(
            Rectangle()
                .stroke(Color.tarotGold.opacity(0.15), lineWidth: 0.5)
        )
    }
}

struct SidebarItem: View {
    let tab: AppTab
    let isSelected: Bool
    let pillNamespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 16, weight: .light))
                    .frame(width: 24, height: 24)
                    .foregroundStyle(isSelected ? Color.tarotGold : Color.tarotIvory.opacity(0.5))
                
                Text(tab.label)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium, design: .serif))
                    .foregroundStyle(isSelected ? Color.tarotIvory : Color.tarotIvory.opacity(0.6))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.tarotGold.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.tarotGold.opacity(0.3), lineWidth: 1)
                        )
                        .matchedGeometryEffect(id: "sidebarPill", in: pillNamespace)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
