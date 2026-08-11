import SwiftUI
import TarotContent
import TarotCore
import TarotData
import TarotNotifications

#if canImport(UIKit)
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
typealias PlatformImage = NSImage
#endif
