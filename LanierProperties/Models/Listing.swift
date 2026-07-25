import Foundation
import CoreLocation

/// A property listing, normalised away from any single MLS/IDX vendor's schema.
///
/// Field names follow the RESO Data Dictionary where a direct equivalent exists,
/// which keeps the mapping in each `ListingService` adapter close to mechanical.
struct Listing: Identifiable, Hashable, Codable, Sendable {

    /// Stable key for the listing. Composed of source + MLS number so listings
    /// from two feeds can coexist without colliding.
    let id: String

    /// The MLS number as displayed to consumers (e.g. "10208555").
    let mlsNumber: String

    /// Originating MLS, used for attribution (e.g. "MemphisTN").
    let mlsSource: String

    var status: ListingStatus
    var propertyType: PropertyType

    var listPrice: Decimal?
    var closePrice: Decimal?

    var streetAddress: String
    var city: String
    var stateOrProvince: String
    var postalCode: String

    var bedrooms: Int?
    /// Total bathrooms including partials, e.g. 2.5.
    var bathrooms: Double?
    var livingAreaSquareFeet: Int?
    var lotSizeAcres: Double?
    var yearBuilt: Int?

    var publicRemarks: String?

    var latitude: Double?
    var longitude: Double?

    var photoURLs: [URL]

    /// Name of the listing brokerage. Required for IDX attribution when the
    /// listing belongs to another office.
    var listingOfficeName: String?
    var listingAgentName: String?

    /// When the MLS last modified this record. Drives cache invalidation.
    var modifiedAt: Date?
    var listedAt: Date?

    /// Canonical web URL for the listing on lanierproperties.net, when known.
    var webURL: URL?

    // MARK: - Derived

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        // Reject the null island; some feeds emit 0,0 for un-geocoded records.
        guard latitude != 0 || longitude != 0 else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var fullAddress: String {
        "\(streetAddress), \(city), \(stateOrProvince) \(postalCode)"
    }

    var cityStateLine: String {
        "\(city), \(stateOrProvince) \(postalCode)"
    }

    var formattedPrice: String {
        guard let listPrice else { return "Price on request" }
        return Self.currencyFormatter.string(from: listPrice as NSDecimalNumber) ?? "Price on request"
    }

    /// Short summary line: "3 bd · 2 ba · 1,850 sqft" — omits anything missing so
    /// land listings don't render "0 bd".
    var featureSummary: String {
        var parts: [String] = []
        if let bedrooms, bedrooms > 0 { parts.append("\(bedrooms) bd") }
        if let bathrooms, bathrooms > 0 { parts.append("\(Self.formatBathrooms(bathrooms)) ba") }
        if let livingAreaSquareFeet, livingAreaSquareFeet > 0 {
            parts.append("\(Self.integerFormatter.string(from: NSNumber(value: livingAreaSquareFeet)) ?? "\(livingAreaSquareFeet)") sqft")
        }
        if let lotSizeAcres, lotSizeAcres > 0 {
            parts.append("\(Self.acreFormatter.string(from: NSNumber(value: lotSizeAcres)) ?? "\(lotSizeAcres)") ac")
        }
        return parts.joined(separator: " · ")
    }

    var pricePerSquareFoot: String? {
        guard let listPrice, let sqft = livingAreaSquareFeet, sqft > 0 else { return nil }
        let perFoot = (listPrice as NSDecimalNumber).doubleValue / Double(sqft)
        return Self.currencyFormatter.string(from: NSNumber(value: perFoot)).map { "\($0)/sqft" }
    }

    // MARK: - Formatters

    private static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 0
        return f
    }()

    private static let integerFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    private static let acreFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        return f
    }()

    /// "2" for a whole number of baths, "2.5" otherwise.
    private static func formatBathrooms(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }
}

// MARK: - Supporting types

enum ListingStatus: String, Codable, CaseIterable, Sendable {
    case active = "Active"
    case activeUnderContract = "Active Under Contract"
    case pending = "Pending"
    case closed = "Closed"
    case comingSoon = "Coming Soon"
    case canceled = "Canceled"
    case expired = "Expired"

    /// Statuses a consumer-facing IDX display should show by default.
    static var publiclyBrowsable: [ListingStatus] {
        [.active, .comingSoon, .activeUnderContract, .pending]
    }

    var displayName: String { rawValue }

    var isAvailable: Bool {
        self == .active || self == .comingSoon
    }
}

enum PropertyType: String, Codable, CaseIterable, Identifiable, Sendable {
    case residential = "Residential"
    case land = "Land"
    case farm = "Farm"
    case commercial = "Commercial"
    case multiFamily = "Multi-Family"
    case manufactured = "Manufactured"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var systemImage: String {
        switch self {
        case .residential: "house.fill"
        case .land: "tree.fill"
        case .farm: "leaf.fill"
        case .commercial: "building.2.fill"
        case .multiFamily: "building.fill"
        case .manufactured: "house.lodge.fill"
        }
    }
}
