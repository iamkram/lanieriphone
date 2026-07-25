import Foundation
import Observation

/// Owns listing state for the app: paging, caching, refresh and error handling.
///
/// Views observe this instead of calling `ListingService` directly, which keeps
/// retry and pagination logic in one place and out of the SwiftUI layer.
@Observable
@MainActor
final class ListingRepository {

    // MARK: - Published state

    private(set) var listings: [Listing] = []
    private(set) var officeListings: [Listing] = []
    private(set) var availableCities: [String] = []

    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var error: ListingServiceError?
    private(set) var totalCount: Int?

    var filters = SearchFilters() {
        didSet {
            guard filters != oldValue else { return }
            searchTask?.cancel()
            searchTask = Task { await self.reload() }
        }
    }

    var hasMore: Bool { nextCursor != nil }

    // MARK: - Private

    private let service: ListingService
    private let cacheTTL: TimeInterval
    private var nextCursor: String?
    private var searchTask: Task<Void, Never>?
    private var lastLoadedAt: Date?
    private let pageSize = 20

    init(service: ListingService, cacheTTL: TimeInterval = 15 * 60) {
        self.service = service
        self.cacheTTL = cacheTTL
    }

    // MARK: - Loading

    /// Loads the first page if we have nothing, or if the cache has gone stale.
    func loadIfNeeded() async {
        let isStale = lastLoadedAt.map { Date().timeIntervalSince($0) > cacheTTL } ?? true
        guard listings.isEmpty || isStale else { return }
        await reload()
    }

    func reload() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let page = try await service.search(filters: filters, cursor: nil, limit: pageSize)
            guard !Task.isCancelled else { return }
            listings = page.listings
            nextCursor = page.nextCursor
            totalCount = page.totalCount
            lastLoadedAt = Date()
        } catch let serviceError as ListingServiceError {
            guard !Task.isCancelled else { return }
            error = serviceError
        } catch is CancellationError {
            // Superseded by a newer search; leave existing results in place.
        } catch {
            self.error = .network(underlying: error.localizedDescription)
        }
    }

    /// Appends the next page. Safe to call repeatedly from `onAppear` of the last
    /// row — re-entrant calls and end-of-list are both no-ops.
    func loadMore() async {
        guard let cursor = nextCursor, !isLoadingMore, !isLoading else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page = try await service.search(filters: filters, cursor: cursor, limit: pageSize)
            guard !Task.isCancelled else { return }
            // Guard against a feed returning overlapping pages.
            let existingIDs = Set(listings.map(\.id))
            listings.append(contentsOf: page.listings.filter { !existingIDs.contains($0.id) })
            nextCursor = page.nextCursor
        } catch let serviceError as ListingServiceError {
            error = serviceError
        } catch {
            self.error = .network(underlying: error.localizedDescription)
        }
    }

    func loadOfficeListings() async {
        guard officeListings.isEmpty else { return }
        do {
            let page = try await service.officeListings(cursor: nil, limit: pageSize)
            officeListings = page.listings
        } catch let serviceError as ListingServiceError {
            error = serviceError
        } catch {
            self.error = .network(underlying: error.localizedDescription)
        }
    }

    func loadCities() async {
        guard availableCities.isEmpty else { return }
        // A failure here only costs us the city filter options, so it stays quiet.
        availableCities = (try? await service.availableCities()) ?? []
    }

    func listing(id: String) async throws -> Listing {
        if let cached = listings.first(where: { $0.id == id }) ?? officeListings.first(where: { $0.id == id }) {
            return cached
        }
        return try await service.listing(id: id)
    }

    func clearError() {
        error = nil
    }
}
