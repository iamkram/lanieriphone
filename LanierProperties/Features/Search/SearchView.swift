import SwiftUI
import MapKit

/// MLS search — the app's equivalent of the website's IDX search and
/// "Our Properties" page, with a native list/map toggle.
struct SearchView: View {

    @Environment(ListingRepository.self) private var repository

    @State private var searchText = ""
    @State private var showFilters = false
    @State private var displayMode: DisplayMode = .list

    enum DisplayMode: String, CaseIterable {
        case list = "List"
        case map = "Map"
    }

    var body: some View {
        @Bindable var repository = repository

        VStack(spacing: 0) {
            modePicker

            Group {
                switch displayMode {
                case .list: listContent
                case .map: ListingMapView(listings: repository.listings)
                }
            }
        }
        .background(Brand.Color.background)
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "City, address or MLS number")
        .onSubmit(of: .search) { applySearchText() }
        .onChange(of: searchText) { _, newValue in
            // Clearing the field should restore the full list immediately.
            if newValue.isEmpty, !repository.filters.searchText.isEmpty {
                repository.filters.searchText = ""
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFilters = true
                } label: {
                    Image(systemName: repository.filters.activeCriteriaCount > 0
                          ? "line.3.horizontal.decrease.circle.fill"
                          : "line.3.horizontal.decrease.circle")
                }
                .accessibilityLabel(repository.filters.activeCriteriaCount > 0
                                    ? "Filters, \(repository.filters.activeCriteriaCount) active"
                                    : "Filters")
            }
        }
        .sheet(isPresented: $showFilters) {
            FiltersView(filters: $repository.filters, cities: repository.availableCities)
        }
        .navigationDestination(for: Listing.self) { listing in
            ListingDetailView(listing: listing)
        }
        .task {
            await repository.loadIfNeeded()
            await repository.loadCities()
        }
    }

    // MARK: - Pieces

    private var modePicker: some View {
        Picker("Display mode", selection: $displayMode) {
            ForEach(DisplayMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Brand.Spacing.pageGutter)
        .padding(.vertical, Brand.Spacing.sm)
        .background(Brand.Color.background)
    }

    @ViewBuilder
    private var listContent: some View {
        if repository.isLoading && repository.listings.isEmpty {
            ProgressView("Loading listings…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = repository.error, repository.listings.isEmpty {
            ErrorStateView(error: error) { await repository.reload() }
                .frame(maxHeight: .infinity)
        } else if repository.listings.isEmpty {
            EmptyStateView(
                title: "No matching properties",
                message: "Try widening your price range or clearing a filter."
            )
            .frame(maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: Brand.Spacing.md) {
                    resultsCountLabel

                    ForEach(repository.listings) { listing in
                        NavigationLink(value: listing) {
                            ListingCard(listing: listing)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            // Prefetch when the last few rows come into view.
                            if listing.id == repository.listings.suffix(3).first?.id {
                                Task { await repository.loadMore() }
                            }
                        }
                    }

                    if repository.isLoadingMore {
                        ProgressView().padding(.vertical, Brand.Spacing.md)
                    }

                    ListingDisclaimerView()
                }
                .brandGutter()
                .padding(.vertical, Brand.Spacing.md)
            }
            .refreshable { await repository.reload() }
        }
    }

    private var resultsCountLabel: some View {
        HStack {
            Text(countText)
                .font(Brand.Font.caption)
                .foregroundStyle(Brand.Color.textSecondary)
            Spacer()
            if repository.filters.activeCriteriaCount > 0 {
                Button("Clear filters") {
                    repository.filters = SearchFilters()
                    searchText = ""
                }
                .font(Brand.Font.caption)
                .foregroundStyle(Brand.Color.primary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var countText: String {
        if let total = repository.totalCount {
            return "\(total) \(total == 1 ? "property" : "properties")"
        }
        return "\(repository.listings.count) shown"
    }

    private func applySearchText() {
        repository.filters.searchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Map

/// Map view of the current results. Listings without coordinates are excluded
/// rather than dropped at 0,0 in the Gulf of Guinea.
struct ListingMapView: View {

    let listings: [Listing]

    @State private var position: MapCameraPosition = .automatic
    @State private var selected: Listing?

    private var mappable: [Listing] {
        listings.filter { $0.coordinate != nil }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position) {
                ForEach(mappable) { listing in
                    if let coordinate = listing.coordinate {
                        Annotation(listing.formattedPrice, coordinate: coordinate) {
                            Button {
                                selected = listing
                            } label: {
                                Text(listing.formattedPrice)
                                    .font(Brand.Font.bodySemibold(12, relativeTo: .caption))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, Brand.Spacing.sm)
                                    .padding(.vertical, 5)
                                    .background(
                                        selected?.id == listing.id ? Brand.Color.accent : Brand.Color.primary,
                                        in: Capsule()
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(listing.formattedPrice), \(listing.fullAddress)")
                        }
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }

            if let selected {
                NavigationLink(value: selected) {
                    ListingCard(listing: selected)
                        .padding(.horizontal, Brand.Spacing.pageGutter)
                        .padding(.bottom, Brand.Spacing.md)
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: selected?.id)
        .overlay {
            if mappable.isEmpty {
                EmptyStateView(
                    title: "Nothing to map",
                    message: "These listings don't have map coordinates in the feed. Switch to List to browse them.",
                    systemImage: "map"
                )
                .background(Brand.Color.background)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SearchView()
            .environment(ListingRepository(service: MockListingService()))
            .environment(SavedListingsStore())
    }
}
