import XCTest
@testable import LanierProperties

final class MockListingServiceTests: XCTestCase {

    private let service = MockListingService()

    func testDefaultSearchReturnsOnlyBrowsableStatuses() async throws {
        let page = try await service.search(filters: SearchFilters(), cursor: nil, limit: 50)
        for listing in page.listings {
            XCTAssertTrue(ListingStatus.publiclyBrowsable.contains(listing.status),
                          "\(listing.status) should not appear in a default search")
        }
    }

    func testPriceFilterIsApplied() async throws {
        var filters = SearchFilters()
        filters.maxPrice = 300_000

        let page = try await service.search(filters: filters, cursor: nil, limit: 50)
        XCTAssertFalse(page.listings.isEmpty)
        for listing in page.listings {
            XCTAssertLessThanOrEqual(listing.listPrice ?? 0, 300_000)
        }
    }

    func testAcreageFilterFindsLargeTracts() async throws {
        var filters = SearchFilters()
        filters.minAcres = 70

        let page = try await service.search(filters: filters, cursor: nil, limit: 50)
        XCTAssertFalse(page.listings.isEmpty, "Sample data includes tracts over 70 acres")
        for listing in page.listings {
            XCTAssertGreaterThanOrEqual(listing.lotSizeAcres ?? 0, 70)
        }
    }

    func testSortByPriceAscending() async throws {
        var filters = SearchFilters()
        filters.sort = .priceLowToHigh

        let page = try await service.search(filters: filters, cursor: nil, limit: 50)
        let prices = page.listings.compactMap(\.listPrice)
        XCTAssertEqual(prices, prices.sorted())
    }

    func testPaginationWalksTheWholeSetWithoutDuplicates() async throws {
        var seen: [String] = []
        var cursor: String?

        repeat {
            let page = try await service.search(filters: SearchFilters(), cursor: cursor, limit: 2)
            seen.append(contentsOf: page.listings.map(\.id))
            cursor = page.nextCursor
        } while cursor != nil

        XCTAssertEqual(Set(seen).count, seen.count, "Pages must not overlap")
        XCTAssertFalse(seen.isEmpty)
    }

    func testUnknownListingIDThrowsNotFound() async {
        do {
            _ = try await service.listing(id: "mock:does-not-exist")
            XCTFail("Expected notFound")
        } catch let error as ListingServiceError {
            guard case .notFound = error else {
                return XCTFail("Expected notFound, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}

final class IDXConfigurationTests: XCTestCase {

    func testMissingCredentialsFallBackToMockRatherThanCrashing() {
        let configuration = IDXConfiguration(
            provider: .resoWebAPI,
            baseURL: nil,
            apiKey: nil,
            originatingSystemName: nil,
            officeKey: nil,
            cacheTTL: 60
        )
        XCTAssertTrue(configuration.makeService() is MockListingService)
        XCTAssertTrue(configuration.statusDescription.contains("sample data"))
    }

    func testFullyConfiguredRESOBuildsRealClient() {
        let configuration = IDXConfiguration(
            provider: .resoWebAPI,
            baseURL: URL(string: "https://api.example.com/odata"),
            apiKey: "token",
            originatingSystemName: "MemphisTN",
            officeKey: "OFFICE123",
            cacheTTL: 60
        )
        XCTAssertTrue(configuration.makeService() is RESOWebAPIClient)
    }
}

final class SearchFiltersTests: XCTestCase {

    func testDefaultFiltersReportNoActiveCriteria() {
        XCTAssertEqual(SearchFilters().activeCriteriaCount, 0)
        XCTAssertTrue(SearchFilters().isDefault)
    }

    func testActiveCriteriaCountTracksEachDimension() {
        var filters = SearchFilters()
        filters.minPrice = 100_000
        filters.minBedrooms = 3
        filters.cities = ["Middleton"]
        XCTAssertEqual(filters.activeCriteriaCount, 3)
    }
}
