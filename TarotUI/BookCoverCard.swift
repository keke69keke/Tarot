import SwiftUI

struct BookCoverCard: View {
    let title: String
    let author: String?
    let accentColor: Color
    @State private var isPressed = false
    @State private var hovered = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Deep mystical background
                LinearGradient(
                    colors: [
                        accentColor.opacity(0.35),
                        Color(red: 0.08, green: 0.04, blue: 0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.tarotGold.opacity(0.45), lineWidth: 1.2)
                )
                .shadow(color: Color.tarotShadow.opacity(0.55), radius: 12, x: 0, y: 8)

                // Decorative corner motif
                VStack {
                    HStack {
                        Circle()
                            .fill(Color.tarotGold.opacity(0.25))
                            .frame(width: 28, height: 28)
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.tarotGold.opacity(0.25))
                            .frame(width: 28, height: 28)
                    }
                }
                .padding(10)

                // Title and author
                VStack(spacing: 8) {
                    Spacer()
                    Text(title)
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)

                    if let author = author, !author.isEmpty {
                        Text(author)
                            .font(.system(size: 10, weight: .regular, design: .serif))
                            .foregroundStyle(Color.tarotGold.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }

                    Spacer()
                }
                .padding(.bottom, 14)
            }
            .frame(width: 110, height: 160)
            .scaleEffect(isPressed || hovered ? 1.04 : 1.0)
            .onTapGesture {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isPressed = false
                }
            }
            #if os(macOS)
            .onHover { hovered = $0 }
            #endif
        }
    }

    init(title: String, author: String? = nil, accentColor: Color = Color(red: 0.42, green: 0.20, blue: 0.60)) {
        self.title = title
        self.author = author
        self.accentColor = accentColor
    }
}
