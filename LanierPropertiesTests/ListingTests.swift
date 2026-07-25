import XCTest
@testable import LanierProperties

final class ListingTests: XCTestCase {

    // MARK: - Feature summary

    func testFeatureSummaryOmitsMissingValues() {
        var listing = MockListingService.sampleListings[0] // land, no beds/baths
        listing.bedrooms = nil
        listing.bathrooms = nil
        listing.livingAreaSquareFeet = nil

        let summary = listing.featureSummary
        XCTAssertFalse(summary.contains("bd"), "Land listings must not advertise 0 bedrooms")
        XCTAssertFalse(summary.contains("ba"))
        XCTAssertTrue(summary.contains("ac"), "Acreage should still be shown")
    }

    func testFeatureSummaryFormatsHalfBaths() {
        var listing = MockListingService.previewListing
        listing.bathrooms = 2.5
        XCTAssertTrue(listing.featureSummary.contains("2.5 ba"))

        listing.bathrooms = 2.0
        XCTAssertTrue(listing.featureSummary.contains("2 ba"),
                      "Whole numbers should not render as 2.0")
    }

    // MARK: - Price

    func testFormattedPriceFallsBackWhenMissing() {
        var listing = MockListingService.previewListing
        listing.listPrice = nil
        XCTAssertEqual(listing.formattedPrice, "Price on request")
    }

    func testPricePerSquareFootIsNilWithoutArea() {
        var listing = MockListingService.previewListing
        listing.livingAreaSquareFeet = nil
        XCTAssertNil(listing.pricePerSquareFoot)
    }

    // MARK: - Coordinates

    func testNullIslandCoordinatesAreRejected() {
        var listing = MockListingService.previewListing
        listing.latitude = 0
        listing.longitude = 0
        XCTAssertNil(listing.coordinate, "0,0 means un-geocoded, not the Gulf of Guinea")
    }

    func testValidCoordinatesAreReturned() {
        let listing = MockListingService.previewListing
        XCTAssertNotNil(listing.coordinate)
    }

    // MARK: - Codable round trip

    func testListingSurvivesEncodeDecode() throws {
        let original = MockListingService.previewListing
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Listing.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}
