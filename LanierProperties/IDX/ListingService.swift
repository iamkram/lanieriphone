import Foundation

/// The single seam between the app and whatever IDX/MLS feed is behind it.
///
/// Every screen in the app talks to this protocol, never to a vendor SDK. Swapping
/// IDX providers — or running against `MockListingService` in previews and tests —
/// is a one-line change in `IDXConfiguration`.
protocol ListingService: Sendable {

    /// Search the feed. `cursor` is the opaque token from a previous `ListingPage`;
    /// pass `nil` for the first page.
    func search(filters: SearchFilters, cursor: String?, limit: Int) async throws -> ListingPage

    /// Fetch a single listing by its stable `Listing.id`.
    func listing(id: String) async throws -> Listing

    /// The brokerage's own listings, for the "Our Properties" screen.
    func officeListings(cursor: String?, limit: Int) async throws -> ListingPage

    /// Cities present in the feed, used to populate the city filter.
    func availableCities() async throws -> [String]
}

// MARK: - Errors

enum ListingServiceError: LocalizedError, Sendable {
    case notConfigured(String)
    case network(underlying: String)
    case unauthorized
    case rateLimited(retryAfter: TimeInterval?)
    case decoding(String)
    case notFound
    case serverError(status: Int)

    var errorDescription: String? {
        switch self {
        case .notConfigured(let detail):
            "Listings aren't available yet. \(detail)"
        case .network:
            "We couldn't reach the listing service. Check your connection and try again."
        case .unauthorized:
            "The listing feed rejected our credentials. Please contact the office."
        case .rateLimited:
            "Too many requests to the listing service. Please try again in a moment."
        case .decoding:
            "We received an unexpected response from the listing service."
        case .notFound:
            "This listing is no longer available."
        case .serverError(let status):
            "The listing service returned an error (\(status)). Please try again."
        }
    }

    /// Whether a retry has any chance of succeeding.
    var isRetryable: Bool {
        switch self {
        case .network, .rateLimited, .serverError: true
        case .notConfigured, .unauthorized, .decoding, .notFound: false
        }
    }
}

// MARK: - Shared HTTP plumbing

/// Small helper shared by the concrete adapters so retry, timeout and error
/// mapping behave identically no matter which vendor is configured.
struct IDXHTTPClient: Sendable {

    let session: URLSession
    let maxRetries: Int

    init(timeout: TimeInterval = 20, maxRetries: Int = 2) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2
        config.waitsForConnectivity = false
        // Listing data changes often; rely on our own repository cache rather
        // than URLCache serving stale prices.
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
        self.maxRetries = maxRetries
    }

    func data(for request: URLRequest) async throws -> Data {
        var lastError: ListingServiceError = .network(underlying: "unknown")

        for attempt in 0...maxRetries {
            if attempt > 0 {
                // Exponential backoff: 0.5s, 1s, 2s…
                let delay = UInt64(0.5 * pow(2, Double(attempt - 1)) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: delay)
            }

            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw ListingServiceError.network(underlying: "Non-HTTP response")
                }

                switch http.statusCode {
                case 200..<300:
                    return data
                case 401, 403:
                    throw ListingServiceError.unauthorized
                case 404:
                    throw ListingServiceError.notFound
                case 429:
                    let retryAfter = (http.value(forHTTPHeaderField: "Retry-After")).flatMap(TimeInterval.init)
                    lastError = .rateLimited(retryAfter: retryAfter)
                case 500..<600:
                    lastError = .serverError(status: http.statusCode)
                default:
                    throw ListingServiceError.serverError(status: http.statusCode)
                }
            } catch let error as ListingServiceError {
                // Non-retryable errors surface immediately.
                guard error.isRetryable else { throw error }
                lastError = error
            } catch {
                lastError = .network(underlying: error.localizedDescription)
            }
        }

        throw lastError
    }

    func decode<T: Decodable>(_ type: T.Type, from request: URLRequest, decoder: JSONDecoder) async throws -> T {
        let data = try await self.data(for: request)
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw ListingServiceError.decoding(String(describing: error))
        }
    }
}
