import SwiftUI

/// Mirrors the website's home page: hero, featured properties, who we are, the
/// service area, and a call to action.
struct HomeView: View {

    var onSeeAllListings: () -> Void = {}

    @Environment(ListingRepository.self) private var repository
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Brand.Spacing.xl) {
                hero
                featuredProperties
                whoWeAre
                serviceArea
                callToAction
                ListingDisclaimerView()
                    .brandGutter()
            }
            .padding(.bottom, Brand.Spacing.xl)
        }
        .background(Brand.Color.background)
        .navigationTitle(BrandInfo.companyName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if let url = URL(string: "tel://\(BrandInfo.phoneDialable)") { openURL(url) }
                } label: {
                    Image(systemName: "phone.fill")
                }
                .accessibilityLabel("Call the office")
            }
        }
        .task {
            await repository.loadOfficeListings()
        }
        .refreshable {
            await repository.reload()
        }
    }

    // MARK: - Sections

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            // Replace `hero-home` in Assets.xcassets with the website's hero
            // photograph; the gradient below keeps text legible over any image.
            Image("hero-home")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 380)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.05), .black.opacity(0.65)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                Text(BrandInfo.tagline.uppercased())
                    .font(Brand.Font.eyebrow)
                    .tracking(1.4)
                    .foregroundStyle(.white.opacity(0.9))

                Text("Find your place in \(BrandInfo.serviceRegionSummary).")
                    .font(Brand.Font.heroTitle)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: onSeeAllListings) {
                    HStack(spacing: Brand.Spacing.sm) {
                        Image(systemName: "magnifyingglass")
                        Text("Search Properties")
                    }
                    .font(Brand.Font.bodySemibold(16, relativeTo: .headline))
                    .foregroundStyle(Brand.Color.primary)
                    .padding(.horizontal, Brand.Spacing.lg)
                    .frame(height: 50)
                    .background(.white, in: RoundedRectangle(cornerRadius: Brand.Radius.button, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, Brand.Spacing.sm)
            }
            .brandGutter()
            .padding(.bottom, Brand.Spacing.lg)
        }
    }

    private var featuredProperties: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.md) {
            SectionHeader(
                title: "Our Properties",
                subtitle: BrandInfo.propertiesIntro,
                actionTitle: "See all",
                action: onSeeAllListings
            )
            .brandGutter()

            if repository.officeListings.isEmpty, repository.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Brand.Spacing.xl)
            } else if let error = repository.error, repository.officeListings.isEmpty {
                ErrorStateView(error: error) {
                    await repository.loadOfficeListings()
                }
            } else if repository.officeListings.isEmpty {
                EmptyStateView(
                    title: "No listings right now",
                    message: "New properties are added often. Give us a call and we'll let you know what's coming.",
                    systemImage: "house"
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Brand.Spacing.md) {
                        ForEach(repository.officeListings) { listing in
                            NavigationLink(value: listing) {
                                ListingCard(listing: listing, style: .compact)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .brandGutter()
                    .padding(.vertical, Brand.Spacing.sm)
                }
            }
        }
        .navigationDestination(for: Listing.self) { listing in
            ListingDetailView(listing: listing)
        }
    }

    private var whoWeAre: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.md) {
            SectionHeader(title: "Who We Are")
            Text(BrandInfo.aboutBody)
                .font(Brand.Font.bodyText)
                .foregroundStyle(Brand.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            NavigationLink {
                AboutView()
            } label: {
                Text("More about us")
                    .font(Brand.Font.bodyMedium(15, relativeTo: .subheadline))
                    .foregroundStyle(Brand.Color.primary)
            }
        }
        .brandGutter()
    }

    private var serviceArea: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.md) {
            SectionHeader(title: "Where We Work")

            // A simple wrapping flow of county chips.
            FlowLayout(spacing: Brand.Spacing.sm) {
                ForEach(BrandInfo.serviceCounties, id: \.self) { county in
                    Text("\(county) County")
                        .font(Brand.Font.bodyMedium(14, relativeTo: .subheadline))
                        .foregroundStyle(Brand.Color.primary)
                        .padding(.horizontal, Brand.Spacing.md)
                        .padding(.vertical, Brand.Spacing.sm)
                        .background(Brand.Color.primary.opacity(0.1), in: Capsule())
                }
            }
        }
        .brandGutter()
    }

    private var callToAction: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.md) {
            Text("Ready to get started?")
                .font(Brand.Font.sectionTitle)
                .foregroundStyle(Brand.Color.textPrimary)

            Text("Whether you're buying your first home or selling family land, we'll walk it with you.")
                .font(Brand.Font.bodyText)
                .foregroundStyle(Brand.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            NavigationLink {
                ContactView()
            } label: {
                Text("Contact Us")
                    .font(Brand.Font.bodySemibold(16, relativeTo: .headline))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Brand.Color.primary, in: RoundedRectangle(cornerRadius: Brand.Radius.button, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(Brand.Spacing.lg)
        .background(Brand.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous))
        .brandGutter()
    }
}

/// Minimal wrapping layout for the county chips — avoids pulling in a dependency
/// for one screen.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[CGSize]] = [[]]
        var currentRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let widthWithSpacing = size.width + (rows[rows.count - 1].isEmpty ? 0 : spacing)
            if currentRowWidth + widthWithSpacing > maxWidth, !rows[rows.count - 1].isEmpty {
                rows.append([size])
                currentRowWidth = size.width
            } else {
                rows[rows.count - 1].append(size)
                currentRowWidth += widthWithSpacing
            }
        }

        let height = rows.reduce(CGFloat.zero) { total, row in
            total + (row.map(\.height).max() ?? 0) + spacing
        } - (rows.isEmpty ? 0 : spacing)

        return CGSize(width: maxWidth == .infinity ? currentRowWidth : maxWidth, height: max(height, 0))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environment(ListingRepository(service: MockListingService()))
            .environment(SavedListingsStore())
    }
}
