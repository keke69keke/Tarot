import SwiftUI

/// Biorhythm section: computes the physical, emotional, intellectual and
/// intuitive cycles from the user's birth date and plots the next month.
struct BiorhythmView: View {
    let model: TarotViewModel
    @State private var birthDate: Date
    @State private var showTomorrow: Bool = false

    /// Fecha persistida en `UserSettings.biorhythmBirthDate` (una sola fuente de verdad).
    init(model: TarotViewModel) {
        self.model = model
        let fallback = Calendar.current.date(byAdding: .year, value: -30, to: .now) ?? .now
        _birthDate = State(initialValue: model.settings.biorhythmBirthDate ?? fallback)
    }

    private enum Cycle {
        case physical, emotional, intellectual, intuitive
        var period: Double { switch self {
            case .physical: return 23
            case .emotional: return 28
            case .intellectual: return 33
            case .intuitive: return 38
        }}
        var name: String { switch self {
            case .physical: return TarotStrings.biorhythmPhysical.localized
            case .emotional: return TarotStrings.biorhythmEmotional.localized
            case .intellectual: return TarotStrings.biorhythmIntellectual.localized
            case .intuitive: return TarotStrings.biorhythmIntuitive.localized
        }}
        var color: Color { switch self {
            case .physical: return Color(red: 0.74, green: 0.56, blue: 0.44) // terracota tenue
            case .emotional: return Color(red: 0.62, green: 0.68, blue: 0.58) // sage
            case .intellectual: return Color(red: 0.56, green: 0.62, blue: 0.70) // slate
            case .intuitive: return Color.tarotGold
        }}
        var symbol: String { switch self {
            case .physical: return "figure.walk"
            case .emotional: return "heart"
            case .intellectual: return "lightbulb"
            case .intuitive: return "eye"
        }}
    }

    private var daysSinceBirth: Double {
        let cal = Calendar.current
        let start = cal.startOfDay(for: birthDate)
        let end = cal.startOfDay(for: .now)
        let days = Double(cal.dateComponents([.day], from: start, to: end).day ?? 0)
        return max(0, days)
    }

    private func value(for cycle: Cycle, dayOffset: Double = 0) -> Double {
        let days = daysSinceBirth + dayOffset
        return sin(2 * Double.pi * (days / cycle.period))
    }

    private func percent(for cycle: Cycle) -> Int {
        Int(((value(for: cycle) + 1) / 2 * 100).rounded())
    }

    private var cycleList: [Cycle] { [.physical, .emotional, .intellectual, .intuitive] }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {

                    // Header — cabecera de página unificada
                    LuxuryPageHeader(
                        eyebrow: TarotStrings.biorhythmEyebrow.localized,
                        title: TarotStrings.biorhythmTitle.localized,
                        subtitle: TarotStrings.biorhythmDescription.localized
                    )

                    // Birth date picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text(TarotStrings.biorhythmBirthDateLabel.localized)
                            .font(.system(size: 12, weight: .semibold, design: .serif))
                            .tracking(0.2)
                            .foregroundStyle(Color.tarotIvory.opacity(0.84))
                        DatePicker(TarotStrings.biorhythmBirthDateLabel.localized, selection: $birthDate, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .tint(Color.tarotGold)
                            .colorScheme(.dark)
                    }
                    .padding(16)
                    .luxuryGlass(cornerRadius: LuxuryRadius.md)

                    // Today's values
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(cycleList, id: \.name) { cycle in
                            cycleCard(cycle)
                        }
                    }

                    // Chart
                    chartCard
                }
                .padding(20)
            }
            .navigationTitle(TarotStrings.biorhythmTitle.localized)
            .onChange(of: birthDate) { newValue in
                model.settings.biorhythmBirthDate = newValue
                model.persistSettings()
            }
            .tarotNightBackground()
        }
    }

    private func cycleCard(_ cycle: Cycle) -> some View {
        let p = percent(for: cycle)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: cycle.symbol).font(.system(size: 11, weight: .light)).foregroundStyle(cycle.color.opacity(0.9))
                Text(cycle.name)
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .tracking(0.1)
                    .foregroundStyle(Color.tarotIvory)
                Spacer()
                Text("\(p)%")
                    .font(.system(size: 13, weight: .semibold, design: .serif).monospacedDigit())
                    .foregroundStyle(cycle.color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08))
                    Capsule().fill(cycle.color.opacity(0.95)).frame(width: geo.size.width * CGFloat(p) / 100)
                }
            }
            .frame(height: 6)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(cycle.name) \(p) por ciento")
            .accessibilityValue(statusText(cycle, p: p))
            .accessibilityAddTraits(.updatesFrequently)
            Text(statusText(cycle, p: p))
                .font(.system(size: 10.5, weight: .regular, design: .serif))
                .foregroundStyle(Color.tarotIvory.opacity(0.52))
                .lineLimit(2)
        }
        .padding(LuxurySpacing.md)
        .luxuryGlass(cornerRadius: LuxuryRadius.md)
    }

    private func statusText(_ cycle: Cycle, p: Int) -> String {
        if p >= 85 { return TarotStrings.biorhythmPeak.localized }
        if p >= 60 { return TarotStrings.biorhythmHigh.localized }
        if p >= 40 { return TarotStrings.biorhythmMedium.localized }
        if p >= 15 { return TarotStrings.biorhythmLow.localized }
        return TarotStrings.biorhythmCritical.localized
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(TarotStrings.next30Days.localized)
                .font(.system(size: 12, weight: .semibold, design: .serif))
                .tracking(0.3)
                .foregroundStyle(Color.tarotIvory)
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.04)).frame(height: 180)
                ChartView(cycles: cycleList.map { ($0.name, $0.color, values(for: $0, days: 30)) }, days: 30)
            }
            .frame(height: 180)
            HStack(spacing: 14) {
                ForEach(cycleList, id: \.name) { c in
                    HStack(spacing: 5) {
                        Circle().fill(c.color.opacity(0.9)).frame(width: 7, height: 7)
                        Text(c.name)
                            .font(.system(size: 10, weight: .medium, design: .serif))
                            .foregroundStyle(Color.tarotIvory.opacity(0.62))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
            }
        }
        .padding(16)
        .luxuryGlass(cornerRadius: LuxuryRadius.md)
    }

    private func values(for cycle: Cycle, days: Int) -> [Double] {
        (0...days).map { value(for: cycle, dayOffset: Double($0)) }
    }
}

private struct ChartView: View {
    let cycles: [(name: String, color: Color, values: [Double])]
    let days: Int

    /// Las cuatro curvas se dibujan solas al abrir la seccion, escalonadas, y
    /// cada una deja un punto marcando su valor de hoy.
    @State private var avance: Double = 0

    var body: some View {
        Canvas { context, size in
            let midY = size.height / 2
            var centerLine = Path()
            centerLine.move(to: CGPoint(x: 0, y: midY))
            centerLine.addLine(to: CGPoint(x: size.width, y: midY))
            context.stroke(centerLine, with: .color(Color.white.opacity(0.15)), lineWidth: 1)

            for (indice, cycle) in cycles.enumerated() {
                guard cycle.values.count > 1 else { continue }
                let stepX = size.width / CGFloat(cycle.values.count - 1)
                var path = Path()
                for (i, v) in cycle.values.enumerated() {
                    let x = CGFloat(i) * stepX
                    let y = midY - CGFloat(v) * (midY - 8)
                    let point = CGPoint(x: x, y: y)
                    if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }
                let progreso = min(1, max(0, (avance - Double(indice) * 0.10) / 0.6))
                context.stroke(path.trimmedPath(from: 0, to: CGFloat(progreso)), with: .color(cycle.color.opacity(0.85)), lineWidth: 1.6)

                if progreso > 0.03 {
                    let hoyY = midY - CGFloat(cycle.values[0]) * (midY - 8)
                    let centro = CGPoint(x: 6, y: hoyY)
                    context.fill(
                        Path(ellipseIn: CGRect(x: centro.x - 3, y: centro.y - 3, width: 6, height: 6)),
                        with: .color(cycle.color)
                    )
                }
            }
        }
        .onAppear {
            avance = 0
            withAnimation(.easeOut(duration: 1.3)) { avance = 1 }
        }
    }
}
