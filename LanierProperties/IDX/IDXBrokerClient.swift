import Foundation

/// IDX Broker (idxbroker.com) Partners API adapter.
///
/// IDX Broker is one of the most common feeds behind WordPress real-estate sites,
/// and its listing permalinks take the shape the website already uses:
/// `/properties/listing/{mlsName}/{listingID}/{city}/{slug}`.
///
/// The Partners API authenticates with an `accesskey` header and exposes
/// `/clients/featured`, `/clients/soldpending` and `/mls/search`-style endpoints.
/// IDX Broker's search endpoint does not paginate with a cursor, so we request a
/// window and page client-side over it.
struct IDXBrokerClient: ListingService {

    let apiKey: String
    let mlsID: String?
    private let http = IDXHTTPClient()
    private let host = URL(string: "https://api.idxbroker.com")!

    init(apiKey: String, mlsID: String?) {
        self.apiKey = apiKey
        self.mlsID = mlsID
    }

    // MARK: - ListingService

    func search(filters: SearchFilters, cursor: String?, limit: Int) async throws -> ListingPage {
        let offset = Int(cursor ?? "0") ?? 0
        var query: [URLQueryItem] = []

        if let minPrice = filters.minPrice { query.append(.init(name: "lp", value: String(minPrice))) }
        if let maxPrice = filters.maxPrice { query.append(.init(name: "hp", value: String(maxPrice))) }
        if let beds = filters.minBedrooms { query.append(.init(name: "bd", value: String(beds))) }
        if let baths = filters.minBathrooms { query.append(.init(name: "ba", value: String(baths))) }
        for city in filters.cities { query.append(.init(name: "city[]", value: city)) }
        if !filters.searchText.isEmpty { query.append(.init(name: "q", value: filters.searchText)) }

        let request = try makeRequest(path: "/clients/search", query: query)
        let all = try await fetchListings(request)

        return paginate(applyClientSideFilters(all, filters: filters), offset: offset, limit: limit)
    }

    func listing(id: String) async throws -> Listing {
        let listingID = id.split(separator: ":", maxSplits: 1).last.map(String.init) ?? id
        // IDX Broker has no single-listing endpoint on every plan, so resolve the
        // listing out of the featured/search results we can reach.
        let request = try makeRequest(path: "/clients/featured", query: [])
        let listings = try await fetchListings(request)
        guard let match = listings.first(where: { $0.mlsNumber == listingID || $0.id == id }) else {
            throw ListingServiceError.notFound
        }
        return match
    }

    func officeListings(cursor: String?, limit: Int) async throws -> ListingPage {
        let offset = Int(cursor ?? "0") ?? 0
        let request = try makeRequest(path: "/clients/featured", query: [])
        let listings = try await fetchListings(request)
        return paginate(listings, offset: offset, limit: limit)
    }

    func availableCities() async throws -> [String] {
        let request = try makeRequest(path: "/clients/cities", query: [])
        let data = try await http.data(for: request)
        // The cities endpoint returns a dictionary keyed by city ID.
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let names = object.values.compactMap { ($0 as? [String: Any])?["name"] as? String }
            if !names.isEmpty { return Array(Set(names)).sorted() }
        }
        // Fall back to deriving cities from the featured set.
        let listings = try await fetchListings(try makeRequest(path: "/clients/featured", query: []))
        return Array(Set(listings.map(\.city))).filter { !$0.isEmpty }.sorted()
    }

    // MARK: - Plumbing

    private func makeRequest(path: String, query: [URLQueryItem]) throws -> URLRequest {
        guard var components = URLComponents(url: host.appendingPathComponent(path),
                                             resolvingAgainstBaseURL: false) else {
            throw ListingServiceError.notConfigured("Could not build the IDX Broker URL.")
        }
        components.queryItems = query.isEmpty ? nil : query

        guard let url = components.url else {
            throw ListingServiceError.notConfigured("Could not build the IDX Broker URL.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "accesskey")
        request.setValue("application/json", forHTTPHeaderField: "outputtype")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func fetchListings(_ request: URLRequest) async throws -> [Listing] {
        let data = try await http.data(for: request)

        // IDX Broker returns either a JSON array or a dictionary keyed by listing
        // ID depending on the endpoint, so accept both shapes.
        let decoder = JSONDecoder()
        if let array = try? decoder.decode([IDXBrokerListing].self, from: data) {
            return array.map(map(raw:))
        }
        if let dictionary = try? decoder.decode([String: IDXBrokerListing].self, from: data) {
            return dictionary.values.map(map(raw:))
        }
        throw ListingServiceError.decoding("Unrecognised IDX Broker payload shape.")
    }

    /// IDX Broker's search parameters don't cover everything the UI offers, so the
    /// remaining criteria are applied locally over the returned window.
    private func applyClientSideFilters(_ listings: [Listing], filters: SearchFilters) -> [Listing] {
        var result = listings

        if !filters.propertyTypes.isEmpty {
            result = result.filter { filters.propertyTypes.contains($0.propertyType) }
        }
        if !filters.statuses.isEmpty {
            result = result.filter { filters.statuses.contains($0.status) }
        }
        if let minAcres = filters.minAcres {
            result = result.filter { ($0.lotSizeAcres ?? 0) >= minAcres }
        }
        if let maxAcres = filters.maxAcres {
            result = result.filter { ($0.lotSizeAcres ?? .greatestFiniteMagnitude) <= maxAcres }
        }

        return sort(result, by: filters.sort)
    }

    private func sort(_ listings: [Listing], by option: SearchFilters.SortOption) -> [Listing] {
        switch option {
        case .newest:
            listings.sorted { ($0.modifiedAt ?? .distantPast) > ($1.modifiedAt ?? .distantPast) }
        case .priceLowToHigh:
            listings.sorted { ($0.listPrice ?? .greatestFiniteMagnitude) < ($1.listPrice ?? .greatestFiniteMagnitude) }
        case .priceHighToLow:
            listings.sorted { ($0.listPrice ?? 0) > ($1.listPrice ?? 0) }
        case .acreageLargest:
            listings.sorted { ($0.lotSizeAcres ?? 0) > ($1.lotSizeAcres ?? 0) }
        }
    }

    private func paginate(_ listings: [Listing], offset: Int, limit: Int) -> ListingPage {
        guard offset < listings.count else {
            return ListingPage(listings: [], nextCursor: nil, totalCount: listings.count)
        }
        let end = min(offset + limit, listings.count)
        let next = end < listings.count ? String(end) : nil
        return ListingPage(listings: Array(listings[offset..<end]), nextCursor: next, totalCount: listings.count)
    }

    // MARK: - Mapping

    private func map(raw: IDXBrokerListing) -> Listing {
        let photos = raw.image?.orderedURLs ?? []
        let acres = raw.acres.flatMap(Double.init)

        return Listing(
            id: "idxbroker:\(raw.listingID ?? UUID().uuidString)",
            mlsNumber: raw.listingID ?? "",
            mlsSource: raw.idxID ?? mlsID ?? "MLS",
            status: mapStatus(raw.propStatus),
            propertyType: mapPropertyType(raw.idxPropType ?? raw.propType),
            listPrice: raw.listingPrice.flatMap { Decimal(string: $0.filter("0123456789.".contains)) },
            closePrice: nil,
            streetAddress: [raw.streetNumber, raw.streetName, raw.streetDirection]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " "),
            city: raw.cityName ?? "",
            stateOrProvince: raw.state ?? "",
            postalCode: raw.zipcode ?? "",
            bedrooms: raw.bedrooms.flatMap(Int.init),
            bathrooms: raw.totalBaths.flatMap(Double.init),
            livingAreaSquareFeet: raw.sqFt.flatMap { Int($0.filter(\.isNumber)) },
            lotSizeAcres: acres,
            yearBuilt: raw.yearBuilt.flatMap(Int.init),
            publicRemarks: raw.remarksConcat,
            latitude: raw.latitude.flatMap(Double.init),
            longitude: raw.longitude.flatMap(Double.init),
            photoURLs: photos,
            listingOfficeName: raw.listingOfficeName,
            listingAgentName: raw.listingAgentName,
            modifiedAt: raw.dateModified.flatMap(RESOWebAPIClient.parseDate),
            listedAt: nil,
            webURL: raw.fullDetailsURL.flatMap(URL.init(string:))
        )
    }

    private func mapStatus(_ raw: String?) -> ListingStatus {
        switch (raw ?? "").lowercased() {
        case let s where s.contains("pending"): .pending
        case let s where s.contains("contract"): .activeUnderContract
        case let s where s.contains("sold") || s.contains("closed"): .closed
        case let s where s.contains("coming"): .comingSoon
        default: .active
        }
    }

    private func mapPropertyType(_ raw: String?) -> PropertyType {
        switch (raw ?? "").lowercased() {
        case let t where t.contains("land") || t.contains("lot"): .land
        case let t where t.contains("farm") || t.contains("agric"): .farm
        case let t where t.contains("commercial"): .commercial
        case let t where t.contains("multi"): .multiFamily
        case let t where t.contains("manufactured") || t.contains("mobile"): .manufactured
        default: .residential
        }
    }
}

// MARK: - Wire format

/// IDX Broker sends most numeric fields as strings, which is why nearly every
/// property here is a `String?` that gets converted during mapping.
private struct IDXBrokerListing: Decodable {
    let listingID: String?
    let idxID: String?
    let idxPropType: String?
    let propType: String?
    let propStatus: String?
    let listingPrice: String?
    let streetNumber: String?
    let streetName: String?
    let streetDirection: String?
    let cityName: String?
    let state: String?
    let zipcode: String?
    let bedrooms: String?
    let totalBaths: String?
    let sqFt: String?
    let acres: String?
    let yearBuilt: String?
    let remarksConcat: String?
    let latitude: String?
    let longitude: String?
    let listingOfficeName: String?
    let listingAgentName: String?
    let dateModified: String?
    let fullDetailsURL: String?
    let image: IDXBrokerImageSet?
}

/// The `image` object is keyed by index ("0", "1", …) plus a `totalCount` entry,
/// so it needs a custom decoder rather than a plain array.
private struct IDXBrokerImageSet: Decodable {
    let orderedURLs: [URL]

    private struct AnyKey: CodingKey {
        var stringValue: String
        var intValue: Int? { Int(stringValue) }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { self.stringValue = String(intValue) }
    }

    private struct ImageEntry: Decodable {
        let url: String?
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyKey.self)
        var indexed: [(Int, URL)] = []

        for key in container.allKeys {
            guard let index = key.intValue else { continue } // skips "totalCount"
            guard let entry = try? container.decode(ImageEntry.self, forKey: key),
                  let raw = entry.url,
                  let url = URL(string: raw) else { continue }
            indexed.append((index, url))
        }

        orderedURLs = indexed.sorted { $0.0 < $1.0 }.map(\.1)
    }
}
