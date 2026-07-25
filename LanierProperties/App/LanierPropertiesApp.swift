import SwiftUI
import UIKit

@main
struct LanierPropertiesApp: App {

    @State private var repository: ListingRepository
    @State private var savedStore = SavedListingsStore()
    private let configuration: IDXConfiguration

    init() {
        let configuration = IDXConfiguration.fromBundle()
        self.configuration = configuration
        _repository = State(initialValue: ListingRepository(
            service: configuration.makeService(),
            cacheTTL: configuration.cacheTTL
        ))
        Self.applyGlobalAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(repository)
                .environment(savedStore)
                .environment(\.idxConfiguration, configuration)
                .tint(Brand.Color.primary)
        }
    }

    /// UIKit-backed surfaces (navigation bars, tab bars) don't pick up SwiftUI
    /// fonts automatically, so the brand typeface is applied once at launch.
    private static func applyGlobalAppearance() {
        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithOpaqueBackground()
        navigationAppearance.backgroundColor = UIColor(named: "BrandBackground")
        navigationAppearance.shadowColor = UIColor(named: "BrandDivider")

        if let display = UIFont(name: Brand.Font.displayFamily, size: 18) {
            navigationAppearance.titleTextAttributes = [.font: display]
        }
        if let displayLarge = UIFont(name: Brand.Font.displayFamily, size: 32) {
            navigationAppearance.largeTitleTextAttributes = [.font: displayLarge]
        }

        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
    }
}

// MARK: - Environment plumbing

private struct IDXConfigurationKey: EnvironmentKey {
    static let defaultValue = IDXConfiguration.mock
}

extension EnvironmentValues {
    var idxConfiguration: IDXConfiguration {
        get { self[IDXConfigurationKey.self] }
        set { self[IDXConfigurationKey.self] = newValue }
    }
}
