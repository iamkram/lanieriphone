import SwiftUI
import UIKit

/// Single source of truth for the Lanier Properties visual identity.
///
/// Every colour, font and metric the app draws comes from here, so matching the
/// website exactly is a one-file change. See `docs/BRANDING.md` for how to lift
/// the real values out of lanierproperties.net and drop them in.
enum Brand {

    // MARK: - Colour

    /// Colours resolve from `Assets.xcassets` so light and dark appearances are
    /// handled by the asset catalog rather than by branching in code.
    enum Color {
        static let primary = SwiftUI.Color("BrandPrimary")
        static let primaryDark = SwiftUI.Color("BrandPrimaryDark")
        static let accent = SwiftUI.Color("BrandAccent")
        static let background = SwiftUI.Color("BrandBackground")
        static let surface = SwiftUI.Color("BrandSurface")
        static let textPrimary = SwiftUI.Color("BrandTextPrimary")
        static let textSecondary = SwiftUI.Color("BrandTextSecondary")
        static let divider = SwiftUI.Color("BrandDivider")

        /// Status colours for listing badges (Active / Pending / Sold).
        static let statusActive = SwiftUI.Color("StatusActive")
        static let statusPending = SwiftUI.Color("StatusPending")
        static let statusSold = SwiftUI.Color("StatusSold")
    }

    // MARK: - Typography

    /// The website's typefaces. `Typography.register()` falls back to the system
    /// font when the custom families are not bundled, so the app always renders.
    enum Font {
        /// Display / headline family used for page titles on the website.
        static let displayFamily = "PlayfairDisplay-SemiBold"
        /// Body family used for paragraph copy on the website.
        static let bodyFamily = "Inter-Regular"
        static let bodyMediumFamily = "Inter-Medium"
        static let bodySemiboldFamily = "Inter-SemiBold"

        /// True when the branded families were successfully loaded from the bundle.
        static var customFontsAvailable: Bool {
            UIFont(name: displayFamily, size: 12) != nil && UIFont(name: bodyFamily, size: 12) != nil
        }

        // Text styles are built on `relativeTo:` so Dynamic Type scales them.
        // This is required for the accessibility bar Apple reviews against.

        static func display(_ size: CGFloat, relativeTo style: SwiftUI.Font.TextStyle = .largeTitle) -> SwiftUI.Font {
            customFontsAvailable
                ? .custom(displayFamily, size: size, relativeTo: style)
                : .system(style, design: .serif).weight(.semibold)
        }

        static func body(_ size: CGFloat, relativeTo style: SwiftUI.Font.TextStyle = .body) -> SwiftUI.Font {
            customFontsAvailable
                ? .custom(bodyFamily, size: size, relativeTo: style)
                : .system(style)
        }

        static func bodyMedium(_ size: CGFloat, relativeTo style: SwiftUI.Font.TextStyle = .body) -> SwiftUI.Font {
            customFontsAvailable
                ? .custom(bodyMediumFamily, size: size, relativeTo: style)
                : .system(style).weight(.medium)
        }

        static func bodySemibold(_ size: CGFloat, relativeTo style: SwiftUI.Font.TextStyle = .body) -> SwiftUI.Font {
            customFontsAvailable
                ? .custom(bodySemiboldFamily, size: size, relativeTo: style)
                : .system(style).weight(.semibold)
        }

        // Named roles, so screens never hardcode a point size.
        static var heroTitle: SwiftUI.Font { display(40, relativeTo: .largeTitle) }
        static var pageTitle: SwiftUI.Font { display(30, relativeTo: .title) }
        static var sectionTitle: SwiftUI.Font { display(23, relativeTo: .title2) }
        static var cardTitle: SwiftUI.Font { bodySemibold(17, relativeTo: .headline) }
        static var bodyText: SwiftUI.Font { body(16, relativeTo: .body) }
        static var caption: SwiftUI.Font { body(13, relativeTo: .caption) }
        static var priceLarge: SwiftUI.Font { bodySemibold(26, relativeTo: .title2) }
        static var eyebrow: SwiftUI.Font { bodyMedium(12, relativeTo: .caption2) }
    }

    // MARK: - Layout

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48

        /// Horizontal page gutter, matched to the website's content inset.
        static let pageGutter: CGFloat = 20
    }

    enum Radius {
        static let card: CGFloat = 12
        static let button: CGFloat = 8
        static let image: CGFloat = 10
        static let pill: CGFloat = 999
    }

    enum Shadow {
        static let cardColor = SwiftUI.Color.black.opacity(0.08)
        static let cardRadius: CGFloat = 10
        static let cardY: CGFloat = 4
    }
}

// MARK: - Reusable modifiers

extension View {
    /// Standard card treatment used by listing cards, agent cards and info panels.
    func brandCard(padding: CGFloat = Brand.Spacing.md) -> some View {
        self
            .padding(padding)
            .background(Brand.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous))
            .shadow(color: Brand.Shadow.cardColor, radius: Brand.Shadow.cardRadius, y: Brand.Shadow.cardY)
    }

    /// Applies the site's horizontal content inset.
    func brandGutter() -> some View {
        padding(.horizontal, Brand.Spacing.pageGutter)
    }
}
