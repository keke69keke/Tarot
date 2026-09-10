import WidgetKit
import SwiftUI

/// Entry point for the Tarot widget extension.
///
/// Delegates to `TarotDailyCardWidget` defined in `TarotWidget.swift`, which
/// contains the full widget implementation (provider, timeline entry, and view).
@main
struct TarotWidgetBundle: WidgetBundle {
    var body: some Widget {
        TarotDailyCardWidget()
    }
}
