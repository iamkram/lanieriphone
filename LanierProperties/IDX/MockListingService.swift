import Foundation

/// Bundled sample data so the app builds, runs, previews and tests without any
/// MLS credentials. Replaced at runtime the moment a real provider is configured.
///
/// The sample records are modelled on the kinds of property the brokerage
/// actually lists — acreage tracts, farms and small-town residential — so layout
/// work is done against realistic content rather than lorem ipsum.
struct MockListingService: ListingService {

    func search(filters: SearchFilters, cursor: String?, limit: Int) async throws -> ListingPage {
        // A short delay keeps loading states honest during development.
        try? await Task.sleep(nanoseconds: 250_000_000)

        var results = Self.sampleListings

        if !filters.searchText.isEmpty {
            let needle = filters.searchText.lowercased()
            results = results.filter {
                $0.fullAddress.lowercased().contains(needle)
                    || $0.mlsNumber.lowercased().contains(needle)
                    || ($0.publicRemarks?.lowercased().contains(needle) ?? false)
            }
        }
        if !filters.cities.isEmpty {
            results = results.filter { filters.cities.contains($0.city) }
        }
        if !filters.propertyTypes.isEmpty {
            results = results.filter { filters.propertyTypes.contains($0.propertyType) }
        }
        if !filters.statuses.isEmpty {
            results = results.filter { filters.statuses.contains($0.status) }
        }
        if let minPrice = filters.minPrice {
            results = results.filter { ($0.listPrice ?? 0) >= Decimal(minPrice) }
        }
        if let maxPrice = filters.maxPrice {
            results = results.filter { ($0.listPrice ?? 0) <= Decimal(maxPrice) }
        }
        if let beds = filters.minBedrooms {
            results = results.filter { ($0.bedrooms ?? 0) >= beds }
        }
        if let baths = filters.minBathrooms {
            results = results.filter { ($0.bathrooms ?? 0) >= Double(baths) }
        }
        if let minAcres = filters.minAcres {
            results = results.filter { ($0.lotSizeAcres ?? 0) >= minAcres }
        }
        if let maxAcres = filters.maxAcres {
            results = results.filter { ($0.lotSizeAcres ?? .greatestFiniteMagnitude) <= maxAcres }
        }

        results = sort(results, by: filters.sort)

        let offset = Int(cursor ?? "0") ?? 0
        guard offset < results.count else {
            return ListingPage(listings: [], nextCursor: nil, totalCount: results.count)
        }
        let end = min(offset + limit, results.count)
        let next = end < results.count ? String(end) : nil
        return ListingPage(listings: Array(results[offset..<end]), nextCursor: next, totalCount: results.count)
    }

    func listing(id: String) async throws -> Listing {
        guard let match = Self.sampleListings.first(where: { $0.id == id }) else {
            throw ListingServiceError.notFound
        }
        return match
    }

    func officeListings(cursor: String?, limit: Int) async throws -> ListingPage {
        try await search(filters: SearchFilters(), cursor: cursor, limit: limit)
    }

    func availableCities() async throws -> [String] {
        Array(Set(Self.sampleListings.map(\.city))).sorted()
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
}

// MARK: - Sample data

extension MockListingService {

    static let sampleListings: [Listing] = [
        Listing(
            id: "mock:10208555",
            mlsNumber: "10208555",
            mlsSource: "MemphisTN",
            status: .active,
            propertyType: .land,
            listPrice: 649_000,
            closePrice: nil,
            streetAddress: "Highway 57",
            city: "Middleton",
            stateOrProvince: "TN",
            postalCode: "38052",
            bedrooms: nil,
            bathrooms: nil,
            livingAreaSquareFeet: nil,
            lotSizeAcres: 81.0,
            yearBuilt: nil,
            publicRemarks: "±81 acres fronting Highway 57 with a mix of open pasture and mature hardwood. "
                + "Excellent road frontage, established interior trails and abundant wildlife. Suitable for a "
                + "homesite, recreational tract or continued agricultural use.",
            latitude: 35.0592,
            longitude: -88.8845,
            photoURLs: [],
            listingOfficeName: BrandInfo.brokerageName,
            listingAgentName: "Lane Lanier",
            modifiedAt: Date().addingTimeInterval(-86_400 * 2),
            listedAt: Date().addingTimeInterval(-86_400 * 21),
            webURL: URL(string: "https://lanierproperties.net/properties/listing/MemphisTN/10208555/Middleton/HIGHWAY-57-HWY")
        ),
        Listing(
            id: "mock:10214902",
            mlsNumber: "10214902",
            mlsSource: "MemphisTN",
            status: .active,
            propertyType: .farm,
            listPrice: 1_750_000,
            closePrice: nil,
            streetAddress: "Pocahontas Road",
            city: "Pocahontas",
            stateOrProvince: "TN",
            postalCode: "38061",
            bedrooms: 3,
            bathrooms: 2.0,
            livingAreaSquareFeet: 2_240,
            lotSizeAcres: 250.0,
            yearBuilt: 1998,
            publicRemarks: "Approximately ±250 acres of West Tennessee farmland with a well-kept three bedroom "
                + "home, equipment barn and two stocked ponds. Row crop income in place with the balance in "
                + "timber and pasture.",
            latitude: 35.0361,
            longitude: -88.8177,
            photoURLs: [],
            listingOfficeName: BrandInfo.brokerageName,
            listingAgentName: "Karen Lanier",
            modifiedAt: Date().addingTimeInterval(-86_400 * 5),
            listedAt: Date().addingTimeInterval(-86_400 * 40),
            webURL: nil
        ),
        Listing(
            id: "mock:10221144",
            mlsNumber: "10221144",
            mlsSource: "MemphisTN",
            status: .active,
            propertyType: .residential,
            listPrice: 289_900,
            closePrice: nil,
            streetAddress: "212 S Main St",
            city: "Middleton",
            stateOrProvince: "TN",
            postalCode: "38052",
            bedrooms: 4,
            bathrooms: 2.5,
            livingAreaSquareFeet: 2_180,
            lotSizeAcres: 0.62,
            yearBuilt: 2016,
            publicRemarks: "Four bedroom, two and a half bath home a short walk from downtown Middleton. Open "
                + "living and kitchen area, covered back porch, fenced yard and a two car garage.",
            latitude: 35.0561,
            longitude: -88.8912,
            photoURLs: [],
            listingOfficeName: BrandInfo.brokerageName,
            listingAgentName: "Christi McCaslin",
            modifiedAt: Date().addingTimeInterval(-86_400),
            listedAt: Date().addingTimeInterval(-86_400 * 9),
            webURL: nil
        ),
        Listing(
            id: "mock:10218877",
            mlsNumber: "10218877",
            mlsSource: "MemphisTN",
            status: .pending,
            propertyType: .land,
            listPrice: 432_000,
            closePrice: nil,
            streetAddress: "Old Stage Road",
            city: "Ramer",
            stateOrProvince: "TN",
            postalCode: "38367",
            bedrooms: nil,
            bathrooms: nil,
            livingAreaSquareFeet: nil,
            lotSizeAcres: 72.0,
            yearBuilt: nil,
            publicRemarks: "72 acre tract in McNairy County with county road frontage, a small creek and "
                + "several cleared building sites. Electricity available at the road.",
            latitude: 35.0722,
            longitude: -88.6218,
            photoURLs: [],
            listingOfficeName: BrandInfo.brokerageName,
            listingAgentName: "Lane Lanier",
            modifiedAt: Date().addingTimeInterval(-86_400 * 8),
            listedAt: Date().addingTimeInterval(-86_400 * 55),
            webURL: nil
        ),
        Listing(
            id: "mock:10223401",
            mlsNumber: "10223401",
            mlsSource: "MemphisTN",
            status: .active,
            propertyType: .residential,
            listPrice: 174_500,
            closePrice: nil,
            streetAddress: "48 County Road 606",
            city: "Walnut",
            stateOrProvince: "MS",
            postalCode: "38683",
            bedrooms: 3,
            bathrooms: 1.0,
            livingAreaSquareFeet: 1_320,
            lotSizeAcres: 1.4,
            yearBuilt: 1974,
            publicRemarks: "Well-maintained three bedroom brick home on 1.4 acres in Tippah County. New roof "
                + "in 2022, detached workshop and mature shade trees.",
            latitude: 34.9483,
            longitude: -88.9033,
            photoURLs: [],
            listingOfficeName: BrandInfo.brokerageName,
            listingAgentName: "Karen Lanier",
            modifiedAt: Date().addingTimeInterval(-86_400 * 3),
            listedAt: Date().addingTimeInterval(-86_400 * 14),
            webURL: nil
        ),
        Listing(
            id: "mock:10225016",
            mlsNumber: "10225016",
            mlsSource: "MemphisTN",
            status: .comingSoon,
            propertyType: .commercial,
            listPrice: 325_000,
            closePrice: nil,
            streetAddress: "101 W Main St",
            city: "Bolivar",
            stateOrProvince: "TN",
            postalCode: "38008",
            bedrooms: nil,
            bathrooms: nil,
            livingAreaSquareFeet: 4_800,
            lotSizeAcres: 0.35,
            yearBuilt: 1952,
            publicRemarks: "Downtown Bolivar commercial building with 4,800 square feet on the square. "
                + "Storefront retail on the ground floor with additional office space above.",
            latitude: 35.2570,
            longitude: -88.9887,
            photoURLs: [],
            listingOfficeName: BrandInfo.brokerageName,
            listingAgentName: "Christi McCaslin",
            modifiedAt: Date(),
            listedAt: Date(),
            webURL: nil
        )
    ]

    /// Convenience for SwiftUI previews.
    static var previewListing: Listing { sampleListings[2] }
}
