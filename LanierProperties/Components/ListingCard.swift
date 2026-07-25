import SwiftUI

/// The listing card used by search results, the home screen carousel and saved
/// listings — matched to the website's property tile.
struct ListingCard: View {

    let listing: Listing
    var style: Style = .full

    enum Style {
        /// Full-width card for vertical lists.
        case full
        /// Fixed-width card for horizontal carousels.
        case compact
    }

    private var imageHeight: CGFloat { style == .compact ? 150 : 210 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            photo
            details
        }
        .frame(width: style == .compact ? 260 : nil, alignment: .leading)
        .background(Brand.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous))
        .shadow(color: Brand.Shadow.cardColor, radius: Brand.Shadow.cardRadius, y: Brand.Shadow.cardY)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Pieces

    private var photo: some View {
        ZStack(alignment: .topLeading) {
            ListingImage(url: listing.photoURLs.first, propertyType: listing.propertyType)
                .frame(height: imageHeight)
                .frame(maxWidth: .infinity)
                .clipped()

            HStack {
                StatusBadge(status: listing.status)
                Spacer()
                SaveButton(listing: listing)
            }
            .padding(Brand.Spacing.sm)
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.xs) {
            Text(listing.formattedPrice)
                .font(Brand.Font.priceLarge)
                .foregroundStyle(Brand.Color.textPrimary)

            Text(listing.streetAddress)
                .font(Brand.Font.cardTitle)
                .foregroundStyle(Brand.Color.textPrimary)
                .lineLimit(1)

            Text(listing.cityStateLine)
                .font(Brand.Font.caption)
                .foregroundStyle(Brand.Color.textSecondary)
                .lineLimit(1)

            if !listing.featureSummary.isEmpty {
                Text(listing.featureSummary)
                    .font(Brand.Font.body(14, relativeTo: .subheadline))
                    .foregroundStyle(Brand.Color.textSecondary)
                    .padding(.top, Brand.Spacing.xs)
                    .lineLimit(1)
            }

            Text("MLS #\(listing.mlsNumber)")
                .font(Brand.Font.body(11, relativeTo: .caption2))
                .foregroundStyle(Brand.Color.textSecondary.opacity(0.8))
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Brand.Spacing.md)
    }

    private var accessibilityDescription: String {
        var parts = [listing.formattedPrice, listing.fullAddress]
        if !listing.featureSummary.isEmpty {
            // Expand the abbreviations so VoiceOver doesn't read "bd" and "ba".
            parts.append(listing.featureSummary
                .replacingOccurrences(of: " bd", with: " bedrooms")
                .replacingOccurrences(of: " ba", with: " bathrooms")
                .replacingOccurrences(of: " sqft", with: " square feet")
                .replacingOccurrences(of: " ac", with: " acres")
                .replacingOccurrences(of: " · ", with: ", "))
        }
        parts.append(listing.status.displayName)
        return parts.joined(separator: ", ")
    }
}

// MARK: - Supporting views

struct StatusBadge: View {
    let status: ListingStatus

    private var color: Color {
        switch status {
        case .active, .comingSoon: Brand.Color.statusActive
        case .pending, .activeUnderContract: Brand.Color.statusPending
        default: Brand.Color.statusSold
        }
    }

    var body: some View {
        Text(status.displayName.uppercased())
            .font(Brand.Font.eyebrow)
            .tracking(0.6)
            .foregroundStyle(.white)
            .padding(.horizontal, Brand.Spacing.sm)
            .padding(.vertical, 5)
            .background(color, in: Capsule())
    }
}

struct SaveButton: View {
    let listing: Listing
    @Environment(SavedListingsStore.self) private var savedStore

    private var isSaved: Bool { savedStore.isSaved(listing) }

    var body: some View {
        Button {
            withAnimation(.snappy) { savedStore.toggle(listing) }
        } label: {
            Image(systemName: isSaved ? "heart.fill" : "heart")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isSaved ? Brand.Color.accent : .white)
                .padding(9)
                .background(.black.opacity(0.35), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSaved ? "Remove from saved" : "Save this listing")
        .accessibilityAddTraits(isSaved ? [.isSelected] : [])
    }
}

/// Async image with a branded placeholder. Land listings frequently have no
/// photos in the feed, so the fallback needs to look intentional.
struct ListingImage: View {
    let url: URL?
    var propertyType: PropertyType = .residential

    var body: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure:
                    placeholder
                case .empty:
                    ZStack {
                        Brand.Color.divider.opacity(0.4)
                        ProgressView()
                    }
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [Brand.Color.primary.opacity(0.16), Brand.Color.primary.opacity(0.32)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: propertyType.systemImage)
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Brand.Color.primary.opacity(0.65))
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    ListingCard(listing: MockListingService.previewListing)
        .padding()
        .environment(SavedListingsStore())
}
