import Foundation

/// User-facing search criteria, translated into vendor query syntax by each
/// `ListingService` adapter.
struct SearchFilters: Equatable, Hashable, Codable, Sendable {

    var searchText: String = ""
    var cities: Set<String> = []
    var propertyTypes: Set<PropertyType> = []
    var statuses: Set<ListingStatus> = Set(ListingStatus.publiclyBrowsable)

    var minPrice: Int?
    var maxPrice: Int?
    var minBedrooms: Int?
    var minBathrooms: Int?
    var minAcres: Double?
    var maxAcres: Double?

    var sort: SortOption = .newest

    /// True when nothing but the default status filter is applied.
    var isDefault: Bool {
        self == SearchFilters()
    }

    /// Count shown on the filter button badge.
    var activeCriteriaCount: Int {
        var count = 0
        if !searchText.isEmpty { count += 1 }
        if !cities.isEmpty { count += 1 }
        if !propertyTypes.isEmpty { count += 1 }
        if minPrice != nil || maxPrice != nil { count += 1 }
        if minBedrooms != nil { count += 1 }
        if minBathrooms != nil { count += 1 }
        if minAcres != nil || maxAcres != nil { count += 1 }
        if statuses != Set(ListingStatus.publiclyBrowsable) { count += 1 }
        return count
    }

    enum SortOption: String, Codable, CaseIterable, Identifiable, Sendable {
        case newest = "Newest"
        case priceLowToHigh = "Price: Low to High"
        case priceHighToLow = "Price: High to Low"
        case acreageLargest = "Acreage: Largest"

        var id: String { rawValue }
        var displayName: String { rawValue }
    }
}

/// One page of results plus the cursor needed to ask for the next one.
struct ListingPage: Sendable {
    let listings: [Listing]
    /// Opaque continuation token. `nil` means there is nothing more to load.
    let nextCursor: String?
    /// Total matches reported by the feed, when the vendor supplies a count.
    let totalCount: Int?

    static let empty = ListingPage(listings: [], nextCursor: nil, totalCount: 0)
}
