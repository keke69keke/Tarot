import SwiftUI

/// Simplified Natal Chart ("Hoja Natal"): computes sun sign, an approximate
/// moon sign and ascendant from the birth date/time, and shows a zodiac wheel
/// with those three positions highlighted.
struct NatalChartView: View {
    @State private var birthDate: Date = (UserDefaults.standard.object(forKey: "natalBirthDate") as? Date) ?? (Calendar.current.date(byAdding: .year, value: -28, to: .now) ?? .now)
    @State private var birthTime: Date = (UserDefaults.standard.object(forKey: "natalBirthTime") as? Date) ?? Calendar.current.startOfDay(for: .now)
    @State private var place: String = UserDefaults.standard.string(forKey: "natalPlace") ?? ""
    @State private var showDetails: Bool = true

    private let zodiacOrder: [ZodiacSign] = [
        .aries, .taurus, .gemini, .cancer, .leo, .virgo,
        .libra, .scorpio, .sagittarius, .capricorn, .aquarius, .pisces
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tarotBackground.ignoresSafeArea()
                Color.tarotBackgroundGradient.ignoresSafeArea()
                AmbientBackgroundView().opacity(0.5)
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {

                        // Header — editorial lujo morado
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                EyebrowLabel(text: TarotStrings.natalEyebrow.localized)
                                Spacer()
                                Image(systemName: "star.circle.fill").font(.system(size: 22, weight: .light)).foregroundStyle(Color.tarotGold.opacity(0.85))
                            }
                            Text(TarotStrings.natalTitle.localized)
                                .font(.system(size: 28, weight: .bold, design: .serif))
                                .tracking(-0.5)
                                .foregroundStyle(Color.tarotIvory)
                            Text(TarotStrings.natalDescription.localized)
                                .font(.system(size: 13, weight: .regular, design: .serif))
                                .foregroundStyle(Color.tarotIvory.opacity(0.60))
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                            GoldDivider().padding(.top, 4)
                        }
                        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                        .luxuryGlass(cornerRadius: 22)

                    // Inputs
                    VStack(alignment: .leading, spacing: 12) {
                        Text(TarotStrings.natalBirthData.localized)
                            .font(.system(size: 12, weight: .semibold, design: .serif))
                            .tracking(0.2)
                            .foregroundStyle(Color.tarotIvory.opacity(0.84))
                        DatePicker(TarotStrings.natalDateLabel.localized, selection: $birthDate, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(.compact).tint(Color.tarotGold).colorScheme(.dark)
                        DatePicker(TarotStrings.natalTimeLabel.localized, selection: $birthTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact).tint(Color.tarotGold).colorScheme(.dark)
                        HStack(spacing: 8) {
                            Image(systemName: "mappin").font(.system(size: 11, weight: .light)).foregroundStyle(Color.tarotGold.opacity(0.85))
                            TextField(TarotStrings.natalPlacePlaceholder.localized, text: $place)
                                .font(.system(size: 13, weight: .regular, design: .serif))
                                .tint(Color.tarotGold)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 8)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.07), lineWidth: 0.7))
                    }
                    .padding(16)
                    .luxuryGlass(cornerRadius: LuxuryRadius.md)

                    // Zodiac wheel with positions
                    wheelCard

                    // Position highlights
                    if showDetails {
                        positionsList
                    }
                }
                .padding(20)
                }
            }
            .navigationTitle("Hoja Natal")
            .onChange(of: birthDate) { UserDefaults.standard.set($0, forKey: "natalBirthDate") }
            .onChange(of: birthTime) { UserDefaults.standard.set($0, forKey: "natalBirthTime") }
            .onChange(of: place) { UserDefaults.standard.set($0, forKey: "natalPlace") }
        }
    }

    // MARK: - Computed positions
    private var sunSign: ZodiacSign { ZodiacSign.fromDate(birthDate) ?? .aries }
    private var sunIndex: Int { zodiacOrder.firstIndex(of: sunSign) ?? 0 }
    private var moonSign: ZodiacSign { zodiacOrder[moonIndex] }
    private var ascSign: ZodiacSign { zodiacOrder[ascIndex] }

    private var moonIndex: Int {
        let cal = Calendar.current
        let ref = cal.date(from: DateComponents(year: 2000, month: 1, day: 6)) ?? .now
        let days = Double(cal.dateComponents([.day], from: ref, to: cal.startOfDay(for: birthDate)).day ?? 0)
        // Moon completes ~12 signs every ~27.32 days; reference ≈ new moon in Capricorn (index 9)
        let cycles = days / 27.32
        let steps = Int((cycles * 12).rounded(.down))
        let idx = ((9 + steps) % 12 + 12) % 12
        return idx
    }

    private var ascIndex: Int {
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: birthTime)
        let hour = Double(comps.hour ?? 12)
        let minute = Double(comps.minute ?? 0)
        // Ascendant advances roughly one sign every two hours
        return Int((hour * 60 + minute) / 120) % 12
    }

    private var wheelCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(TarotStrings.natalWheelTitle.localized)
                .font(.system(size: 12, weight: .semibold, design: .serif))
                .tracking(0.3)
                .foregroundStyle(Color.tarotIvory)
            ZStack {
                ZodiacWheelView(highlightIndices: [sunIndex: Color.tarotGold, moonIndex: Color.white.opacity(0.82), ascIndex: Color.tarotGold.opacity(0.55)])
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                VStack(spacing: 3) {
                    Text(sunSign.symbol).font(.system(size: 28, weight: .thin)).foregroundStyle(Color.tarotGold)
                    Text(sunSign.rawValue).font(.system(size: 11, weight: .semibold, design: .serif)).tracking(0.6).foregroundStyle(Color.tarotIvory)
                    Text(sunSign.dates).font(.system(size: 10, weight: .regular, design: .serif)).foregroundStyle(Color.tarotIvory.opacity(0.42))
                }
            }
        }
        .padding(16)
        .luxuryGlass(cornerRadius: LuxuryRadius.md)
    }

    private var positionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            positionRow(title: TarotStrings.natalSun.localized, sign: sunSign, detail: TarotStrings.natalSunDetail.localized)
            positionRow(title: TarotStrings.natalMoon.localized, sign: moonSign, detail: TarotStrings.natalMoonDetail.localized)
            positionRow(title: TarotStrings.natalAscendant.localized, sign: ascSign, detail: TarotStrings.natalAscDetail.localized)
            if !place.trimmingCharacters(in: .whitespaces).isEmpty {
                Text("Lugar: \(place)")
                    .font(.system(size: 11, weight: .regular, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.56))
            }
        }
    }

    private func positionRow(title: String, sign: ZodiacSign, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(sign.symbol).font(.system(size: 28, weight: .thin)).frame(width: 36)
                .foregroundStyle(Color.tarotGold.opacity(0.92))
            VStack(alignment: .leading, spacing: 3) {
                Text("\(title) en \(sign.rawValue)")
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .tracking(0.1)
                    .foregroundStyle(Color.tarotIvory)
                Text(detail)
                    .font(.system(size: 12, weight: .regular, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.58))
                    .lineSpacing(2)
                Text(String(format: TarotStrings.natalElementPrefix.localized, sign.element, sign.dates))
                    .font(.system(size: 10, weight: .medium, design: .serif))
                    .tracking(0.4)
                    .foregroundStyle(Color.tarotGold.opacity(0.72))
            }
            Spacer()
        }
        .padding(14)
        .luxuryGlass(cornerRadius: LuxuryRadius.md)
    }
}


// MARK: - Zodiac wheel
private struct ZodiacWheelView: View {
    let highlightIndices: [Int: Color]

    private let signs: [ZodiacSign] = [
        .aries, .taurus, .gemini, .cancer, .leo, .virgo,
        .libra, .scorpio, .sagittarius, .capricorn, .aquarius, .pisces
    ]

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 18
            let outer = radius
            let inner = radius * 0.78
            let slice = (2 * Double.pi) / 12

            for (i, sign) in signs.enumerated() {
                let start = -Double.pi / 2 + Double(i) * slice
                let end = start + slice
                var seg = Path()
                seg.move(to: CGPoint(x: center.x + inner * CGFloat(cos(start)), y: center.y + inner * CGFloat(sin(start))))
                seg.addArc(center: center, radius: inner, startAngle: .radians(start), endAngle: .radians(end), clockwise: false)
                seg.addLine(to: CGPoint(x: center.x + outer * CGFloat(cos(end)), y: center.y + outer * CGFloat(sin(end))))
                seg.addArc(center: center, radius: outer, startAngle: .radians(end), endAngle: .radians(start), clockwise: true)
                seg.closeSubpath()

                let color = highlightIndices[i] ?? .clear
                let highlighted = highlightIndices[i] != nil
                context.fill(seg, with: .color(highlighted ? color.opacity(0.28) : Color.white.opacity(0.06)))
                context.stroke(seg, with: .color(highlighted ? color.opacity(0.8) : Color.white.opacity(0.18)), lineWidth: 1.2)

                let midAngle = start + slice / 2
                let labelRadius = (outer + inner) / 2
                let lx = center.x + labelRadius * CGFloat(cos(midAngle))
                let ly = center.y + labelRadius * CGFloat(sin(midAngle))
                context.draw(Text(sign.symbol).font(.system(size: 15)), at: CGPoint(x: lx, y: ly))
            }

            var ring = Path()
            ring.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            context.stroke(ring, with: .color(Color.tarotGold.opacity(0.5)), lineWidth: 1.5)
        }
    }
}

extension ZodiacSign {
    /// Returns the sun sign for a given date.
    static func fromDate(_ date: Date) -> ZodiacSign? {
        let cal = Calendar.current
        let comps = cal.dateComponents([.month, .day], from: date)
        guard let month = comps.month, let day = comps.day else { return nil }
        let md = month * 100 + day
        switch md {
        case 120...219: return .aquarius
        case 220...320: return .pisces
        case 321...419: return .aries
        case 420...520: return .taurus
        case 521...620: return .gemini
        case 621...722: return .cancer
        case 723...822: return .leo
        case 823...922: return .virgo
        case 923...1022: return .libra
        case 1023...1121: return .scorpio
        case 1122...1221: return .sagittarius
        default: return .capricorn
        }
    }
}

