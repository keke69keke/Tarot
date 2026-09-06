import SwiftUI
import TarotCore
import TarotData

struct BookContentBlock: View {

    let text: String
    @State private var expanded = false
    @Environment(\.colorScheme) private var colorScheme

    private var sanitizedText: String {
        Self.sanitize(text)
    }

    private let previewLength = 450

    var isLong: Bool { sanitizedText.count > previewLength }
    var displayText: String {
        guard isLong && !expanded else { return sanitizedText }
        let prefix = String(sanitizedText.prefix(previewLength))
        let lastSpace = prefix.lastIndex(of: " ") ?? prefix.endIndex
        return String(prefix[..<lastSpace]) + "…"
    }

    public static func sanitize(_ raw: String) -> String {
        var s = raw

        // ── 1. Common OCR character substitutions ───────────────────────────
        let ocr: [(String, String)] = [
            // Accented vowels misread
            ("Tü", "Tú"), ("tü", "tú"), ("ü", "ú"),
            ("ä", "á"), ("ë", "é"), ("ï", "í"), ("ö", "ó"),
            ("Ä", "Á"), ("Ë", "É"), ("Ï", "Í"), ("Ö", "Ó"), ("Ü", "Ú"),
            // Inverted punctuation
            ("¿ ", "¿"), (" ?", "?"), (" !", "!"),
            // Common word errors
            ("derache", "derecho"), ("clernidad", "eternidad"),
            ("jy vive", "¡y vive"), ("sı́", "sí"), ("asl", "así"),
            ("mâs", "más"), ("mas ", "más "), ("tamblén", "también"),
            ("lntuitivo", "Intuitivo"), ("lnicio", "Inicio"),
            ("revel ación", "revelación"), ("transfor mación", "transformación"),
            ("poten cial", "potencial"), ("espiri tual", "espiritual"),
            // OCR ligatures
            ("ﬁ", "fi"), ("ﬂ", "fl"), ("ﬀ", "ff"), ("ﬃ", "ffi"), ("ﬄ", "ffl"),
            // Hyphen artifacts from line-break hyphenation
            ("- ", ""), (" -\n", ""),
            // Double spaces
            ("  ", " "),
        ]
        for (from, to) in ocr {
            s = s.replacingOccurrences(of: from, with: to)
        }

        // Remove double-spaces
        while s.contains("  ") { s = s.replacingOccurrences(of: "  ", with: " ") }

        // ── 2. Strip TOC residues ────────────────────────────────────────────
        if s.contains("Arcanos Menores:") || s.contains("Reina de bastos") || s.contains("........") {
            let markers = ["•", "Significado", "La carta", "Esta carta", "Simboliza", "Descripción"]
            var earliest: String.Index? = nil
            for m in markers {
                if let r = s.range(of: m) {
                    if earliest == nil || r.lowerBound < earliest! { earliest = r.lowerBound }
                }
            }
            if let start = earliest { s = String(s[start...]) }
        }

        // ── 3. Remove dot-leaders (table of contents style) ─────────────────
        // e.g. "Capítulo 1 .......... 12"
        let dotPattern = try? NSRegularExpression(pattern: "\\.{3,}\\s*\\d*", options: [])
        if let pattern = dotPattern {
            s = pattern.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: "")
        }

        // ── 4. Join mid-sentence line breaks ────────────────────────────────
        let lines = s.components(separatedBy: .newlines)
        var cleanLines: [String] = []
        for line in lines {
            let l = line.trimmingCharacters(in: .whitespaces)
            if l.isEmpty {
                // Preserve paragraph breaks (empty lines)
                if cleanLines.last != "" { cleanLines.append("") }
            } else if cleanLines.isEmpty {
                cleanLines.append(l)
            } else {
                let last = cleanLines.last!
                // Join if previous line doesn't end with sentence-ending punctuation
                // and current line doesn't start with a capital (continuation)
                let endsWithPunctuation = last.last.map { [".", "!", "?", ":", "•", ";", "»", "\""].contains($0) } ?? false
                let startsNewSentence = l.first?.isUppercase == true && last.last == "."
                if !endsWithPunctuation && !startsNewSentence && !last.isEmpty {
                    cleanLines[cleanLines.count - 1] = last + " " + l
                } else {
                    cleanLines.append(l)
                }
            }
        }

        // ── 5. Remove consecutive empty lines (max 1 paragraph break) ───────
        var result: [String] = []
        var lastWasEmpty = false
        for line in cleanLines {
            if line.isEmpty {
                if !lastWasEmpty { result.append(line) }
                lastWasEmpty = true
            } else {
                result.append(line)
                lastWasEmpty = false
            }
        }

        return result.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Attribution header
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("GUÍA DEFINITIVA")
                    .font(.system(size: 9, weight: .semibold, design: .serif))
                    .tracking(2.5)
                    .foregroundStyle(Color.tarotGold.opacity(0.85))
                Text("·")
                    .font(.system(size: 9, design: .serif))
                    .foregroundStyle(Color.tarotGold.opacity(0.40))
                Text("FIEBIG & BÜRGER")
                    .font(.system(size: 9, weight: .regular, design: .serif))
                    .tracking(2)
                    .foregroundStyle(Color.tarotGold.opacity(0.60))
                Spacer()
                Image(systemName: "book.closed")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.tarotGold.opacity(0.50))
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 10)

            // Thin rule
            Rectangle()
                .fill(Color.tarotGold.opacity(0.22))
                .frame(height: 0.5)
                .padding(.horizontal, 18)

            // Body text — serif, generous line height, multiline
            Text(displayText)
                .font(.system(size: 15, weight: .regular, design: .serif))
                .lineSpacing(8)
                .foregroundStyle(colorScheme == .dark
                    ? Color(red: 0.88, green: 0.85, blue: 0.78)
                    : Color(red: 0.15, green: 0.12, blue: 0.08))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, isLong ? 4 : 18)
                .animation(.easeInOut(duration: 0.28), value: expanded)

            // Expand / collapse button
            if isLong {
                Button {
                    withAnimation(.easeInOut(duration: 0.28)) { expanded.toggle() }
                } label: {
                    HStack(spacing: 5) {
                        Text(expanded ? "Mostrar menos" : "Continuar leyendo")
                            .font(.system(size: 12, weight: .regular, design: .serif))
                            .tracking(0.5)
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(Color.tarotGold.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark
                    ? Color(red: 0.12, green: 0.09, blue: 0.06).opacity(0.85)
                    : Color(red: 0.97, green: 0.94, blue: 0.88).opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.tarotGold.opacity(0.20), lineWidth: 0.5)
        )
        .shadow(color: Color(red: 0.40, green: 0.22, blue: 0.04).opacity(0.08), radius: 8, x: 0, y: 2)
    }
}
