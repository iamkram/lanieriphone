import Foundation

/// RESO Web API (OData v4) adapter.
///
/// This is the standard modern MLS feed and what Bridge Interactive, MLS Grid,
/// Trestle and Spark/FlexMLS all expose. The Memphis-area MLS (MAAR), which the
/// website's listing URLs reference as `MemphisTN`, is reachable this way.
///
/// Queries hit the `Property` resource with `$filter`, `$orderby`, `$top` and
/// `$skip`; media comes from the expanded `Media` collection.
struct RESOWebAPIClient: ListingService {

    let baseURL: URL
    let accessToken: String
    let originatingSystemName: String?
    let officeKey: String?
    private let http = IDXHTTPClient()

    init(baseURL: URL, accessToken: String, originatingSystemName: String?, officeKey: String?) {
        self.baseURL = baseURL
        self.accessToken = accessToken
        self.originatingSystemName = originatingSystemName
        self.officeKey = officeKey
    }

    // MARK: - ListingService

    func search(filters: SearchFilters, cursor: String?, limit: Int) async throws -> ListingPage {
        let skip = Int(cursor ?? "0") ?? 0
        let request = try makeRequest(
            filter: oDataFilter(for: filters),
            orderBy: oDataOrderBy(for: filters.sort),
            top: limit,
            skip: skip
        )
        return try await fetchPage(request, limit: limit, skip: skip)
    }

    func listing(id: String) async throws -> Listing {
        // `Listing.id` is "reso:<ListingKey>"; recover the MLS key.
        let key = id.split(separator: ":", maxSplits: 1).last.map(String.init) ?? id
        let request = try makeRequest(
            filter: "ListingKey eq '\(escape(key))'",
            orderBy: nil,
            top: 1,
            skip: 0
        )
        let page = try await fetchPage(request, limit: 1, skip: 0)
        guard let listing = page.listings.first else { throw ListingServiceError.notFound }
        return listing
    }

    func officeListings(cursor: String?, limit: Int) async throws -> ListingPage {
        guard let officeKey else {
            // Without an office key we can't distinguish our listings from the
            // rest of the feed; showing everything would be misleading.
            throw ListingServiceError.notConfigured("The brokerage office key is not set.")
        }
        let skip = Int(cursor ?? "0") ?? 0
        var clauses = ["ListOfficeKey eq '\(escape(officeKey))'"]
        clauses.append(statusClause(for: Set(ListingStatus.publiclyBrowsable)))
        let request = try makeRequest(
            filter: clauses.joined(separator: " and "),
            orderBy: "ModificationTimestamp desc",
            top: limit,
            skip: skip
        )
        return try await fetchPage(request, limit: limit, skip: skip)
    }

    func availableCities() async throws -> [String] {
        // One page of active listings is enough to populate the city picker
        // without a second round trip per city.
        let page = try await search(filters: SearchFilters(), cursor: nil, limit: 200)
        return Array(Set(page.listings.map(\.city))).sorted()
    }

    // MARK: - Request building

    private func makeRequest(filter: String?, orderBy: String?, top: Int, skip: Int) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent("Property"),
                                             resolvingAgainstBaseURL: false) else {
            throw ListingServiceError.notConfigured("The RESO base URL is invalid.")
        }

        var items: [URLQueryItem] = [
            URLQueryItem(name: "$top", value: String(top)),
            URLQueryItem(name: "$skip", value: String(skip)),
            URLQueryItem(name: "$count", value: "true"),
            URLQueryItem(name: "$expand", value: "Media")
        ]
        if let filter, !filter.isEmpty { items.append(URLQueryItem(name: "$filter", value: filter)) }
        if let orderBy { items.append(URLQueryItem(name: "$orderby", value: orderBy)) }
        components.queryItems = items

        guard let url = components.url else {
            throw ListingServiceError.notConfigured("Could not build the RESO query URL.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func fetchPage(_ request: URLRequest, limit: Int, skip: Int) async throws -> ListingPage {
        let decoder = JSONDecoder()
        let response = try await http.decode(RESOResponse.self, from: request, decoder: decoder)
        let listings = response.value.map(map(resource:))
        // OData gives us `@odata.nextLink`, but a skip cursor is enough here and
        // keeps the cursor opaque-but-simple.
        let next = listings.count == limit ? String(skip + limit) : nil
        return ListingPage(listings: listings, nextCursor: next, totalCount: response.count)
    }

    // MARK: - Filter translation

    private func oDataFilter(for filters: SearchFilters) -> String {
        var clauses: [String] = []

        if let originatingSystemName {
            clauses.append("OriginatingSystemName eq '\(escape(originatingSystemName))'")
        }

        clauses.append(statusClause(for: filters.statuses))

        if !filters.cities.isEmpty {
            let cityClause = filters.cities
                .map { "City eq '\(escape($0))'" }
                .joined(separator: " or ")
            clauses.append("(\(cityClause))")
        }

        if !filters.propertyTypes.isEmpty {
            let typeClause = filters.propertyTypes
                .map { "PropertyType eq '\(escape(resoPropertyType(for: $0)))'" }
                .joined(separator: " or ")
            clauses.append("(\(typeClause))")
        }

        if let minPrice = filters.minPrice { clauses.append("ListPrice ge \(minPrice)") }
        if let maxPrice = filters.maxPrice { clauses.append("ListPrice le \(maxPrice)") }
        if let beds = filters.minBedrooms { clauses.append("BedroomsTotal ge \(beds)") }
        if let baths = filters.minBathrooms { clauses.append("BathroomsTotalInteger ge \(baths)") }
        if let minAcres = filters.minAcres { clauses.append("LotSizeAcres ge \(minAcres)") }
        if let maxAcres = filters.maxAcres { clauses.append("LotSizeAcres le \(maxAcres)") }

        if !filters.searchText.isEmpty {
            let term = escape(filters.searchText)
            clauses.append("(contains(UnparsedAddress,'\(term)') or contains(City,'\(term)') or ListingId eq '\(term)')")
        }

        return clauses.joined(separator: " and ")
    }

    private func statusClause(for statuses: Set<ListingStatus>) -> String {
        let effective = statuses.isEmpty ? Set(ListingStatus.publiclyBrowsable) : statuses
        let clause = effective
            .map { "StandardStatus eq '\(escape($0.rawValue))'" }
            .sorted()
            .joined(separator: " or ")
        return "(\(clause))"
    }

    private func oDataOrderBy(for sort: SearchFilters.SortOption) -> String {
        switch sort {
        case .newest: "ModificationTimestamp desc"
        case .priceLowToHigh: "ListPrice asc"
        case .priceHighToLow: "ListPrice desc"
        case .acreageLargest: "LotSizeAcres desc"
        }
    }

    private func resoPropertyType(for type: PropertyType) -> String {
        // RESO's PropertyType enumeration uses a fixed vocabulary.
        switch type {
        case .residential: "Residential"
        case .land: "Land"
        case .farm: "Farm"
        case .commercial: "Commercial Sale"
        case .multiFamily: "Residential Income"
        case .manufactured: "Manufactured In Park"
        }
    }

    /// OData string literals escape a single quote by doubling it.
    private func escape(_ value: String) -> String {
        value.replacingOccurrences(of: "'", with: "''")
    }

    // MARK: - Mapping

    private func map(resource: RESOProperty) -> Listing {
        let photos = (resource.Media ?? [])
            .sorted { ($0.Order ?? 0) < ($1.Order ?? 0) }
            .compactMap { $0.MediaURL.flatMap(URL.init(string:)) }

        return Listing(
            id: "reso:\(resource.ListingKey)",
            mlsNumber: resource.ListingId ?? resource.ListingKey,
            mlsSource: resource.OriginatingSystemName ?? originatingSystemName ?? "MLS",
            status: ListingStatus(rawValue: resource.StandardStatus ?? "") ?? .active,
            propertyType: mapPropertyType(resource.PropertyType, subType: resource.PropertySubType),
            listPrice: resource.ListPrice.map { Decimal($0) },
            closePrice: resource.ClosePrice.map { Decimal($0) },
            streetAddress: resource.UnparsedAddress
                ?? [resource.StreetNumber, resource.StreetName, resource.StreetSuffix]
                    .compactMap { $0 }.joined(separator: " "),
            city: resource.City ?? "",
            stateOrProvince: resource.StateOrProvince ?? "",
            postalCode: resource.PostalCode ?? "",
            bedrooms: resource.BedroomsTotal,
            bathrooms: resource.BathroomsTotalDecimal ?? resource.BathroomsTotalInteger.map(Double.init),
            livingAreaSquareFeet: resource.LivingArea.map { Int($0) },
            lotSizeAcres: resource.LotSizeAcres,
            yearBuilt: resource.YearBuilt,
            publicRemarks: resource.PublicRemarks,
            latitude: resource.Latitude,
            longitude: resource.Longitude,
            photoURLs: photos,
            listingOfficeName: resource.ListOfficeName,
            listingAgentName: resource.ListAgentFullName,
            modifiedAt: resource.ModificationTimestamp.flatMap(Self.parseDate),
            listedAt: resource.OnMarketDate.flatMap(Self.parseDate),
            webURL: nil
        )
    }

    private func mapPropertyType(_ type: String?, subType: String?) -> PropertyType {
        switch (type ?? "").lowercased() {
        case let t where t.contains("land") || t.contains("lot"): .land
        case let t where t.contains("farm"): .farm
        case let t where t.contains("commercial"): .commercial
        case let t where t.contains("income") || t.contains("multi"): .multiFamily
        default:
            (subType ?? "").lowercased().contains("manufactured") ? .manufactured : .residential
        }
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoFormatterNoFraction = ISO8601DateFormatter()

    static func parseDate(_ string: String) -> Date? {
        isoFormatter.date(from: string) ?? isoFormatterNoFraction.date(from: string)
    }
}

// MARK: - Wire format

/// Field names deliberately match the RESO Data Dictionary casing so the mapping
/// above reads as a direct translation of the spec.
private struct RESOResponse: Decodable {
    let value: [RESOProperty]
    let count: Int?

    enum CodingKeys: String, CodingKey {
        case value
        case count = "@odata.count"
    }
}

private struct RESOProperty: Decodable {
    let ListingKey: String
    let ListingId: String?
    let OriginatingSystemName: String?
    let StandardStatus: String?
    let PropertyType: String?
    let PropertySubType: String?
    let ListPrice: Double?
    let ClosePrice: Double?
    let UnparsedAddress: String?
    let StreetNumber: String?
    let StreetName: String?
    let StreetSuffix: String?
    let City: String?
    let StateOrProvince: String?
    let PostalCode: String?
    let BedroomsTotal: Int?
    let BathroomsTotalInteger: Int?
    let BathroomsTotalDecimal: Double?
    let LivingArea: Double?
    let LotSizeAcres: Double?
    let YearBuilt: Int?
    let PublicRemarks: String?
    let Latitude: Double?
    let Longitude: Double?
    let ListOfficeName: String?
    let ListAgentFullName: String?
    let ModificationTimestamp: String?
    let OnMarketDate: String?
    let Media: [RESOMedia]?
}

private struct RESOMedia: Decodable {
    let MediaURL: String?
    let Order: Int?
}
