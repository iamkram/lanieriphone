import SwiftUI
import MapKit

/// Full listing detail — the app's version of the website's
/// `/properties/listing/{mls}/{id}/{city}/{slug}` page.
struct ListingDetailView: View {

    let listing: Listing

    @Environment(SavedListingsStore.self) private var savedStore
    @Environment(\.openURL) private var openURL
    @State private var selectedPhotoIndex = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Brand.Spacing.lg) {
                photoGallery
                header
                factsGrid
                if let remarks = listing.publicRemarks, !remarks.isEmpty {
                    description(remarks)
                }
                locationMap
                contactActions
                attribution
                ListingDisclaimerView()
            }
            .brandGutter()
            .padding(.bottom, Brand.Spacing.xxl)
        }
        .background(Brand.Color.background)
        .navigationTitle(listing.streetAddress)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: shareURL, subject: Text(listing.streetAddress), message: Text(shareMessage)) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share this listing")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    savedStore.toggle(listing)
                } label: {
                    Image(systemName: savedStore.isSaved(listing) ? "heart.fill" : "heart")
                        .foregroundStyle(savedStore.isSaved(listing) ? Brand.Color.accent : Brand.Color.primary)
                }
                .accessibilityLabel(savedStore.isSaved(listing) ? "Remove from saved" : "Save this listing")
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var photoGallery: some View {
        if listing.photoURLs.isEmpty {
            ListingImage(url: nil, propertyType: listing.propertyType)
                .frame(height: 260)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.image, style: .continuous))
        } else {
            VStack(spacing: Brand.Spacing.sm) {
                TabView(selection: $selectedPhotoIndex) {
                    ForEach(Array(listing.photoURLs.enumerated()), id: \.offset) { index, url in
                        ListingImage(url: url, propertyType: listing.propertyType)
                            .clipped()
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.image, style: .continuous))

                Text("\(selectedPhotoIndex + 1) of \(listing.photoURLs.count)")
                    .font(Brand.Font.caption)
                    .foregroundStyle(Brand.Color.textSecondary)
                    .accessibilityLabel("Photo \(selectedPhotoIndex + 1) of \(listing.photoURLs.count)")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
            HStack {
                StatusBadge(status: listing.status)
                Spacer()
                if let perFoot = listing.pricePerSquareFoot {
                    Text(perFoot)
                        .font(Brand.Font.caption)
                        .foregroundStyle(Brand.Color.textSecondary)
                }
            }

            Text(listing.formattedPrice)
                .font(Brand.Font.pageTitle)
                .foregroundStyle(Brand.Color.textPrimary)

            Text(listing.streetAddress)
                .font(Brand.Font.cardTitle)
                .foregroundStyle(Brand.Color.textPrimary)

            Text(listing.cityStateLine)
                .font(Brand.Font.bodyText)
                .foregroundStyle(Brand.Color.textSecondary)

            if !listing.featureSummary.isEmpty {
                Text(listing.featureSummary)
                    .font(Brand.Font.bodyMedium(15, relativeTo: .subheadline))
                    .foregroundStyle(Brand.Color.textPrimary)
                    .padding(.top, Brand.Spacing.xs)
            }
        }
    }

    private var factsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: Brand.Spacing.md) {
            FactRow(label: "MLS #", value: listing.mlsNumber)
            FactRow(label: "Type", value: listing.propertyType.displayName)
            if let beds = listing.bedrooms, beds > 0 {
                FactRow(label: "Bedrooms", value: String(beds))
            }
            if let baths = listing.bathrooms, baths > 0 {
                FactRow(label: "Bathrooms", value: baths.truncatingRemainder(dividingBy: 1) == 0
                        ? String(Int(baths)) : String(format: "%.1f", baths))
            }
            if let sqft = listing.livingAreaSquareFeet, sqft > 0 {
                FactRow(label: "Living Area", value: "\(sqft) sqft")
            }
            if let acres = listing.lotSizeAcres, acres > 0 {
                FactRow(label: "Lot Size", value: String(format: "%.2f acres", acres))
            }
            if let year = listing.yearBuilt, year > 0 {
                FactRow(label: "Year Built", value: String(year))
            }
            if let listed = listing.listedAt {
                FactRow(label: "Listed", value: listed.formatted(date: .abbreviated, time: .omitted))
            }
        }
        .padding(Brand.Spacing.md)
        .background(Brand.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous))
    }

    private func description(_ remarks: String) -> some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
            Text("About This Property")
                .font(Brand.Font.sectionTitle)
                .foregroundStyle(Brand.Color.textPrimary)
            Text(remarks)
                .font(Brand.Font.bodyText)
                .foregroundStyle(Brand.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var locationMap: some View {
        if let coordinate = listing.coordinate {
            VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                Text("Location")
                    .font(Brand.Font.sectionTitle)
                    .foregroundStyle(Brand.Color.textPrimary)

                Map(initialPosition: .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                ))) {
                    Marker(listing.streetAddress, coordinate: coordinate)
                        .tint(Brand.Color.primary)
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.image, style: .continuous))
                .allowsHitTesting(false)
                .accessibilityLabel("Map showing \(listing.fullAddress)")

                Button {
                    openInMaps(coordinate)
                } label: {
                    Label("Open in Maps", systemImage: "arrow.triangle.turn.up.right.circle")
                        .font(Brand.Font.bodyMedium(15, relativeTo: .subheadline))
                        .foregroundStyle(Brand.Color.primary)
                }
            }
        }
    }

    private var contactActions: some View {
        VStack(spacing: Brand.Spacing.sm) {
            PrimaryButton(title: "Ask About This Property", systemImage: "envelope.fill") {
                openEmailInquiry()
            }
            SecondaryButton(title: "Call \(BrandInfo.phoneDisplay)", systemImage: "phone.fill") {
                if let url = URL(string: "tel://\(BrandInfo.phoneDialable)") { openURL(url) }
            }
        }
    }

    @ViewBuilder
    private var attribution: some View {
        // MLS rules require naming the listing brokerage when it isn't ours.
        if let office = listing.listingOfficeName {
            VStack(alignment: .leading, spacing: 2) {
                Text("Listed by \(office)")
                    .font(Brand.Font.caption)
                    .foregroundStyle(Brand.Color.textSecondary)
                if let agent = listing.listingAgentName {
                    Text(agent)
                        .font(Brand.Font.caption)
                        .foregroundStyle(Brand.Color.textSecondary)
                }
                Text("Data source: \(listing.mlsSource)")
                    .font(Brand.Font.body(11, relativeTo: .caption2))
                    .foregroundStyle(Brand.Color.textSecondary.opacity(0.8))
            }
        }
    }

    // MARK: - Actions

    private var shareURL: URL {
        listing.webURL ?? BrandInfo.websiteURL
    }

    private var shareMessage: String {
        "\(listing.formattedPrice) — \(listing.fullAddress) (MLS #\(listing.mlsNumber)), listed with \(BrandInfo.brokerageName)."
    }

    private func openInMaps(_ coordinate: CLLocationCoordinate2D) {
        let placemark = MKPlacemark(coordinate: coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = listing.streetAddress
        item.openInMaps(launchOptions: [MKLaunchOptionsMapTypeKey: MKMapType.standard.rawValue])
    }

    private func openEmailInquiry() {
        let subject = "Inquiry: \(listing.streetAddress) (MLS #\(listing.mlsNumber))"
        let body = """
        Hello \(BrandInfo.brokerageName),

        I'd like more information about \(listing.fullAddress), MLS #\(listing.mlsNumber).

        Thank you.
        """

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = BrandInfo.email
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]

        if let url = components.url {
            openURL(url)
        }
    }
}

#Preview {
    NavigationStack {
        ListingDetailView(listing: MockListingService.previewListing)
            .environment(SavedListingsStore())
    }
}
