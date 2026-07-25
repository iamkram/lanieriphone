import SwiftUI

/// Search refinements, presented as a sheet.
///
/// Edits are staged locally and only written back on "Apply", so dragging a
/// price slider doesn't fire a network request per frame.
struct FiltersView: View {

    @Binding var filters: SearchFilters
    let cities: [String]

    @Environment(\.dismiss) private var dismiss
    @State private var draft: SearchFilters

    init(filters: Binding<SearchFilters>, cities: [String]) {
        _filters = filters
        self.cities = cities
        _draft = State(initialValue: filters.wrappedValue)
    }

    private static let priceOptions: [Int] = [
        50_000, 100_000, 150_000, 200_000, 250_000, 300_000, 400_000,
        500_000, 750_000, 1_000_000, 1_500_000, 2_000_000
    ]

    var body: some View {
        NavigationStack {
            Form {
                priceSection
                propertyTypeSection
                bedsBathsSection
                acreageSection
                if !cities.isEmpty { citySection }
                statusSection
                sortSection
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") { draft = SearchFilters() }
                        .disabled(draft.isDefault)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        filters = draft
                        dismiss()
                    }
                    .font(Brand.Font.bodySemibold(16, relativeTo: .headline))
                }
            }
        }
    }

    // MARK: - Sections

    private var priceSection: some View {
        Section("Price") {
            Picker("Minimum", selection: $draft.minPrice) {
                Text("No minimum").tag(Int?.none)
                ForEach(Self.priceOptions, id: \.self) { value in
                    Text(currency(value)).tag(Int?.some(value))
                }
            }
            Picker("Maximum", selection: $draft.maxPrice) {
                Text("No maximum").tag(Int?.none)
                ForEach(Self.priceOptions, id: \.self) { value in
                    Text(currency(value)).tag(Int?.some(value))
                }
            }
        }
        .onChange(of: draft.maxPrice) { _, newValue in
            // Keep the range coherent rather than silently returning nothing.
            if let newValue, let min = draft.minPrice, min > newValue {
                draft.minPrice = nil
            }
        }
    }

    private var propertyTypeSection: some View {
        Section("Property Type") {
            ForEach(PropertyType.allCases) { type in
                Toggle(isOn: binding(for: type)) {
                    Label(type.displayName, systemImage: type.systemImage)
                }
            }
        }
    }

    private var bedsBathsSection: some View {
        Section("Beds & Baths") {
            Picker("Bedrooms", selection: $draft.minBedrooms) {
                Text("Any").tag(Int?.none)
                ForEach(1...6, id: \.self) { count in
                    Text("\(count)+").tag(Int?.some(count))
                }
            }
            Picker("Bathrooms", selection: $draft.minBathrooms) {
                Text("Any").tag(Int?.none)
                ForEach(1...5, id: \.self) { count in
                    Text("\(count)+").tag(Int?.some(count))
                }
            }
        }
    }

    private var acreageSection: some View {
        Section {
            Picker("Minimum acres", selection: $draft.minAcres) {
                Text("Any").tag(Double?.none)
                ForEach([1.0, 5.0, 10.0, 25.0, 50.0, 100.0, 250.0], id: \.self) { value in
                    Text("\(Int(value))+ acres").tag(Double?.some(value))
                }
            }
        } header: {
            Text("Acreage")
        } footer: {
            Text("Useful for farms, timber and recreational tracts.")
        }
    }

    private var citySection: some View {
        Section("City") {
            ForEach(cities, id: \.self) { city in
                Button {
                    if draft.cities.contains(city) {
                        draft.cities.remove(city)
                    } else {
                        draft.cities.insert(city)
                    }
                } label: {
                    HStack {
                        Text(city)
                            .foregroundStyle(Brand.Color.textPrimary)
                        Spacer()
                        if draft.cities.contains(city) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Brand.Color.primary)
                        }
                    }
                }
                .accessibilityAddTraits(draft.cities.contains(city) ? [.isSelected] : [])
            }
        }
    }

    private var statusSection: some View {
        Section("Status") {
            ForEach(ListingStatus.publiclyBrowsable, id: \.self) { status in
                Toggle(status.displayName, isOn: binding(for: status))
            }
        }
    }

    private var sortSection: some View {
        Section("Sort") {
            Picker("Sort by", selection: $draft.sort) {
                ForEach(SearchFilters.SortOption.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }
    }

    // MARK: - Helpers

    private func binding(for type: PropertyType) -> Binding<Bool> {
        Binding(
            get: { draft.propertyTypes.contains(type) },
            set: { isOn in
                if isOn { draft.propertyTypes.insert(type) } else { draft.propertyTypes.remove(type) }
            }
        )
    }

    private func binding(for status: ListingStatus) -> Binding<Bool> {
        Binding(
            get: { draft.statuses.contains(status) },
            set: { isOn in
                if isOn {
                    draft.statuses.insert(status)
                } else {
                    draft.statuses.remove(status)
                    // An empty status set would return nothing; fall back to the
                    // default browsable set instead of an empty screen.
                    if draft.statuses.isEmpty {
                        draft.statuses = Set(ListingStatus.publiclyBrowsable)
                    }
                }
            }
        )
    }

    private func currency(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
}

#Preview {
    FiltersView(filters: .constant(SearchFilters()), cities: ["Middleton", "Bolivar", "Ramer"])
}
