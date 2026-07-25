import Foundation

// MARK: - Proxy client (recommended for production)

/// Talks to a small JSON endpoint hosted on lanierproperties.net that fronts the
/// MLS feed.
///
/// This is the recommended production configuration: the MLS credentials stay on
/// the server, the server enforces the feed's rate limits and caching rules, and
/// rotating a key doesn't require an App Store release. A reference server
/// implementation is sketched in `docs/IDX_INTEGRATION.md`.
struct ProxyListingClient: ListingService {

    let baseURL: URL
    let apiKey: String?
    private let http = IDXHTTPClient()

    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    func search(filters: SearchFilters, cursor: String?, limit: Int) async throws -> ListingPage {
        var query: [URLQueryItem] = [URLQueryItem(name: "limit", value: String(limit))]
        if let cursor { query.append(.init(name: "cursor", value: cursor)) }
        if !filters.searchText.isEmpty { query.append(.init(name: "q", value: filters.searchText)) }
        if let minPrice = filters.minPrice { query.append(.init(name: "minPrice", value: String(minPrice))) }
        if let maxPrice = filters.maxPrice { query.append(.init(name: "maxPrice", value: String(maxPrice))) }
        if let beds = filters.minBedrooms { query.append(.init(name: "minBeds", value: String(beds))) }
        if let baths = filters.minBathrooms { query.append(.init(name: "minBaths", value: String(baths))) }
        if let minAcres = filters.minAcres { query.append(.init(name: "minAcres", value: String(minAcres))) }
        if let maxAcres = filters.maxAcres { query.append(.init(name: "maxAcres", value: String(maxAcres))) }
        query.append(contentsOf: filters.cities.map { URLQueryItem(name: "city", value: $0) })
        query.append(contentsOf: filters.propertyTypes.map { URLQueryItem(name: "propertyType", value: $0.rawValue) })
        query.append(contentsOf: filters.statuses.map { URLQueryItem(name: "status", value: $0.rawValue) })
        query.append(.init(name: "sort", value: filters.sort.rawValue))

        return try await fetchPage(path: "listings", query: query)
    }

    func listing(id: String) async throws -> Listing {
        let request = try makeRequest(path: "listings/\(id)", query: [])
        return try await http.decode(Listing.self, from: request, decoder: decoder)
    }

    func officeListings(cursor: String?, limit: Int) async throws -> ListingPage {
        var query: [URLQueryItem] = [URLQueryItem(name: "limit", value: String(limit))]
        if let cursor { query.append(.init(name: "cursor", value: cursor)) }
        return try await fetchPage(path: "listings/office", query: query)
    }

    func availableCities() async throws -> [String] {
        let request = try makeRequest(path: "cities", query: [])
        return try await http.decode([String].self, from: request, decoder: decoder)
    }

    // MARK: - Plumbing

    private struct PageResponse: Decodable {
        let listings: [Listing]
        let nextCursor: String?
        let totalCount: Int?
    }

    private func fetchPage(path: String, query: [URLQueryItem]) async throws -> ListingPage {
        let request = try makeRequest(path: path, query: query)
        let response = try await http.decode(PageResponse.self, from: request, decoder: decoder)
        return ListingPage(listings: response.listings,
                           nextCursor: response.nextCursor,
                           totalCount: response.totalCount)
    }

    private func makeRequest(path: String, query: [URLQueryItem]) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path),
                                             resolvingAgainstBaseURL: false) else {
            throw ListingServiceError.notConfigured("The proxy base URL is invalid.")
        }
        components.queryItems = query.isEmpty ? nil : query

        guard let url = components.url else {
            throw ListingServiceError.notConfigured("Could not build the proxy URL.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}

// MARK: - SimplyRETS

/// SimplyRETS adapter — a RETS/RESO gateway used by many smaller brokerages.
///
/// Authenticates with HTTP Basic using a "key:secret" pair supplied as the
/// configured API key.
struct SimplyRETSClient: ListingService {

    /// Expected format: `apiKey:apiSecret`.
    let credentials: String
    private let http = IDXHTTPClient()
    private let host = URL(string: "https://api.simplyrets.com")!

    func search(filters: SearchFilters, cursor: String?, limit: Int) async throws -> ListingPage {
        let offset = Int(cursor ?? "0") ?? 0
        var query: [URLQueryItem] = [
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset))
        ]
        if let minPrice = filters.minPrice { query.append(.init(name: "minprice", value: String(minPrice))) }
        if let maxPrice = filters.maxPrice { query.append(.init(name: "maxprice", value: String(maxPrice))) }
        if let beds = filters.minBedrooms { query.append(.init(name: "minbeds", value: String(beds))) }
        if let baths = filters.minBathrooms { query.append(.init(name: "minbaths", value: String(baths))) }
        if !filters.searchText.isEmpty { query.append(.init(name: "q", value: filters.searchText)) }
        query.append(contentsOf: filters.cities.map { URLQueryItem(name: "cities", value: $0) })

        let request = try makeRequest(path: "/properties", query: query)
        let raw = try await http.decode([SimplyRETSProperty].self, from: request, decoder: JSONDecoder())
        let listings = raw.map(map(raw:))
        let next = listings.count == limit ? String(offset + limit) : nil
        return ListingPage(listings: listings, nextCursor: next, totalCount: nil)
    }

    func listing(id: String) async throws -> Listing {
        let mlsID = id.split(separator: ":", maxSplits: 1).last.map(String.init) ?? id
        let request = try makeRequest(path: "/properties/\(mlsID)", query: [])
        let raw = try await http.decode(SimplyRETSProperty.self, from: request, decoder: JSONDecoder())
        return map(raw: raw)
    }

    func officeListings(cursor: String?, limit: Int) async throws -> ListingPage {
        // SimplyRETS scopes the whole feed to the subscribing brokerage on most
        // plans, so the office view is the default search.
        try await search(filters: SearchFilters(), cursor: cursor, limit: limit)
    }

    func availableCities() async throws -> [String] {
        let page = try await search(filters: SearchFilters(), cursor: nil, limit: 100)
        return Array(Set(page.listings.map(\.city))).filter { !$0.isEmpty }.sorted()
    }

    private func makeRequest(path: String, query: [URLQueryItem]) throws -> URLRequest {
        guard var components = URLComponents(url: host.appendingPathComponent(path),
                                             resolvingAgainstBaseURL: false),
              let encoded = credentials.data(using: .utf8)?.base64EncodedString() else {
            throw ListingServiceError.notConfigured("SimplyRETS credentials are invalid.")
        }
        components.queryItems = query.isEmpty ? nil : query

        guard let url = components.url else {
            throw ListingServiceError.notConfigured("Could not build the SimplyRETS URL.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func map(raw: SimplyRETSProperty) -> Listing {
        Listing(
            id: "simplyrets:\(raw.mlsId.map(String.init) ?? raw.listingId ?? UUID().uuidString)",
            mlsNumber: raw.listingId ?? raw.mlsId.map(String.init) ?? "",
            mlsSource: raw.mls?.status ?? "MLS",
            status: ListingStatus(rawValue: raw.mls?.status ?? "") ?? .active,
            propertyType: raw.property?.type?.lowercased().contains("land") == true ? .land : .residential,
            listPrice: raw.listPrice.map { Decimal($0) },
            closePrice: nil,
            streetAddress: raw.address?.full ?? "",
            city: raw.address?.city ?? "",
            stateOrProvince: raw.address?.state ?? "",
            postalCode: raw.address?.postalCode ?? "",
            bedrooms: raw.property?.bedrooms,
            bathrooms: raw.property?.bathsFull.map(Double.init),
            livingAreaSquareFeet: raw.property?.area,
            lotSizeAcres: raw.property?.acres,
            yearBuilt: raw.property?.yearBuilt,
            publicRemarks: raw.remarks,
            latitude: raw.geo?.lat,
            longitude: raw.geo?.lng,
            photoURLs: (raw.photos ?? []).compactMap(URL.init(string:)),
            listingOfficeName: raw.office?.name,
            listingAgentName: raw.agent?.firstName.map { "\($0) \(raw.agent?.lastName ?? "")" },
            modifiedAt: raw.modified.flatMap(RESOWebAPIClient.parseDate),
            listedAt: nil,
            webURL: nil
        )
    }
}

// MARK: - SimplyRETS wire format

private struct SimplyRETSProperty: Decodable {
    struct Address: Decodable {
        let full: String?
        let city: String?
        let state: String?
        let postalCode: String?
    }
    struct Property: Decodable {
        let bedrooms: Int?
        let bathsFull: Int?
        let area: Int?
        let acres: Double?
        let yearBuilt: Int?
        let type: String?
    }
    struct Geo: Decodable {
        let lat: Double?
        let lng: Double?
    }
    struct MLSInfo: Decodable {
        let status: String?
    }
    struct Office: Decodable {
        let name: String?
    }
    struct Agent: Decodable {
        let firstName: String?
        let lastName: String?
    }

    let mlsId: Int?
    let listingId: String?
    let listPrice: Double?
    let remarks: String?
    let modified: String?
    let address: Address?
    let property: Property?
    let geo: Geo?
    let mls: MLSInfo?
    let office: Office?
    let agent: Agent?
    let photos: [String]?
}
