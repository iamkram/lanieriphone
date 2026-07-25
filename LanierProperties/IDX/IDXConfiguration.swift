import Foundation

/// Which listing feed the app talks to, and the credentials for it.
///
/// **No secrets are committed to this repository.** Values are read from the app's
/// Info.plist, which is populated at build time from `Configuration/*.xcconfig`
/// (git-ignored). See `docs/IDX_INTEGRATION.md` for the exact setup.
///
/// Note that an API key shipped inside an app binary is extractable by anyone who
/// downloads it. For a public App Store release, prefer `.proxy` — point the app
/// at a small server endpoint on lanierproperties.net that holds the MLS
/// credentials and applies the feed's rate limits. Most MLS IDX agreements
/// require exactly this.
enum IDXProvider: String {
    /// RESO Web API (OData) — the modern MLS standard. Bridge Interactive,
    /// Spark/FlexMLS, MLS Grid and Trestle all speak this.
    case resoWebAPI = "reso"
    /// IDX Broker (idxbroker.com) Partners API.
    case idxBroker = "idxbroker"
    /// SimplyRETS, a common RETS/RESO gateway.
    case simplyRETS = "simplyrets"
    /// A JSON endpoint hosted on lanierproperties.net that fronts the MLS feed.
    /// Recommended for production.
    case proxy = "proxy"
    /// Bundled sample data — used for SwiftUI previews, tests and when nothing
    /// is configured yet, so the app is always runnable.
    case mock = "mock"
}

struct IDXConfiguration: Sendable {

    let provider: IDXProvider
    let baseURL: URL?
    let apiKey: String?
    /// RESO feeds scope queries by originating system; IDX Broker uses this for
    /// the MLS "ID" (e.g. "a001").
    let originatingSystemName: String?
    /// The brokerage's MLS office key, used to select "Our Properties".
    let officeKey: String?

    /// How long a cached page stays fresh. MLS agreements typically require IDX
    /// displays to refresh at least every 12 hours; we're well inside that.
    let cacheTTL: TimeInterval

    // MARK: - Loading

    /// Reads configuration from Info.plist, falling back to `.mock` so a fresh
    /// clone builds and runs with no credentials at all.
    static func fromBundle(_ bundle: Bundle = .main) -> IDXConfiguration {
        let raw = bundle.object(forInfoDictionaryKey: "IDXProvider") as? String ?? ""
        let provider = IDXProvider(rawValue: raw.lowercased()) ?? .mock

        return IDXConfiguration(
            provider: provider,
            baseURL: (bundle.object(forInfoDictionaryKey: "IDXBaseURL") as? String)
                .flatMap { $0.isEmpty ? nil : URL(string: $0) },
            apiKey: (bundle.object(forInfoDictionaryKey: "IDXAPIKey") as? String)
                .flatMap { $0.isEmpty ? nil : $0 },
            originatingSystemName: (bundle.object(forInfoDictionaryKey: "IDXOriginatingSystemName") as? String)
                .flatMap { $0.isEmpty ? nil : $0 },
            officeKey: (bundle.object(forInfoDictionaryKey: "IDXOfficeKey") as? String)
                .flatMap { $0.isEmpty ? nil : $0 },
            cacheTTL: 15 * 60
        )
    }

    static let mock = IDXConfiguration(
        provider: .mock,
        baseURL: nil,
        apiKey: nil,
        originatingSystemName: "MemphisTN",
        officeKey: nil,
        cacheTTL: 15 * 60
    )

    /// Builds the concrete adapter for this configuration.
    ///
    /// Falls back to mock data rather than crashing when a provider is selected
    /// but its credentials are missing — a half-configured build still runs, and
    /// the Settings screen surfaces the problem.
    func makeService() -> ListingService {
        switch provider {
        case .mock:
            return MockListingService()

        case .resoWebAPI:
            guard let baseURL, let apiKey else { return MockListingService() }
            return RESOWebAPIClient(
                baseURL: baseURL,
                accessToken: apiKey,
                originatingSystemName: originatingSystemName,
                officeKey: officeKey
            )

        case .idxBroker:
            guard let apiKey else { return MockListingService() }
            return IDXBrokerClient(apiKey: apiKey, mlsID: originatingSystemName)

        case .simplyRETS:
            guard let apiKey else { return MockListingService() }
            return SimplyRETSClient(credentials: apiKey)

        case .proxy:
            guard let baseURL else { return MockListingService() }
            return ProxyListingClient(baseURL: baseURL, apiKey: apiKey)
        }
    }

    /// Human-readable status for the diagnostics row in Settings.
    var statusDescription: String {
        switch provider {
        case .mock:
            return "Sample data (no MLS feed configured)"
        default:
            let credentialsPresent = apiKey != nil && (provider == .idxBroker || provider == .simplyRETS || baseURL != nil)
            return credentialsPresent
                ? "Connected — \(provider.rawValue)"
                : "\(provider.rawValue) selected but credentials are missing; showing sample data"
        }
    }
}
