import SwiftUI

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Brand.Font.sectionTitle)
                    .foregroundStyle(Brand.Color.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(Brand.Font.caption)
                        .foregroundStyle(Brand.Color.textSecondary)
                }
            }
            Spacer(minLength: Brand.Spacing.sm)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(Brand.Font.bodyMedium(14, relativeTo: .subheadline))
                    .foregroundStyle(Brand.Color.primary)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Brand.Spacing.sm) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(Brand.Font.bodySemibold(16, relativeTo: .headline))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            // 50pt clears Apple's 44pt minimum touch target.
            .frame(height: 50)
            .background(Brand.Color.primary, in: RoundedRectangle(cornerRadius: Brand.Radius.button, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryButton: View {
    let title: String
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Brand.Spacing.sm) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(Brand.Font.bodySemibold(16, relativeTo: .headline))
            .foregroundStyle(Brand.Color.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: Brand.Radius.button, style: .continuous)
                    .stroke(Brand.Color.primary, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - States

/// Shown when a listing request fails. Always offers a way forward — retry when
/// the error is transient, a phone call to the office when it isn't.
struct ErrorStateView: View {
    let error: ListingServiceError
    var retry: (() async -> Void)?

    var body: some View {
        VStack(spacing: Brand.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Brand.Color.textSecondary)

            Text(error.errorDescription ?? "Something went wrong.")
                .font(Brand.Font.bodyText)
                .foregroundStyle(Brand.Color.textSecondary)
                .multilineTextAlignment(.center)

            if error.isRetryable, let retry {
                Button("Try Again") { Task { await retry() } }
                    .font(Brand.Font.bodySemibold(15, relativeTo: .headline))
                    .foregroundStyle(Brand.Color.primary)
            } else {
                CallOfficeButton()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Brand.Spacing.xl)
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    var systemImage: String = "magnifyingglass"

    var body: some View {
        VStack(spacing: Brand.Spacing.sm) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Brand.Color.textSecondary)
                .padding(.bottom, Brand.Spacing.xs)

            Text(title)
                .font(Brand.Font.cardTitle)
                .foregroundStyle(Brand.Color.textPrimary)

            Text(message)
                .font(Brand.Font.bodyText)
                .foregroundStyle(Brand.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Brand.Spacing.xl)
    }
}

// MARK: - Contact actions

/// Opening `tel:` needs no permission and is the fastest path to a human, so it
/// appears on most error and empty states.
struct CallOfficeButton: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            if let url = URL(string: "tel://\(BrandInfo.phoneDialable)") {
                openURL(url)
            }
        } label: {
            Label("Call \(BrandInfo.phoneDisplay)", systemImage: "phone.fill")
                .font(Brand.Font.bodySemibold(15, relativeTo: .headline))
                .foregroundStyle(Brand.Color.primary)
        }
        .accessibilityLabel("Call the office at \(BrandInfo.phoneDisplay)")
    }
}

// MARK: - Legal

/// MLS attribution and the fair-housing statement. Required on IDX displays and
/// referenced from every screen that shows listing data.
struct ListingDisclaimerView: View {
    var showFairHousing = true

    var body: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
            Divider()
                .background(Brand.Color.divider)
                .padding(.bottom, Brand.Spacing.xs)

            Text(BrandInfo.idxDisclaimer)
                .font(Brand.Font.body(11, relativeTo: .caption2))
                .foregroundStyle(Brand.Color.textSecondary)

            if showFairHousing {
                HStack(alignment: .top, spacing: Brand.Spacing.sm) {
                    Image(systemName: "house.circle")
                        .foregroundStyle(Brand.Color.textSecondary)
                        .accessibilityHidden(true)
                    Text(BrandInfo.fairHousingStatement)
                        .font(Brand.Font.body(11, relativeTo: .caption2))
                        .foregroundStyle(Brand.Color.textSecondary)
                }
                .padding(.top, Brand.Spacing.xs)
            }
        }
        .padding(.vertical, Brand.Spacing.md)
    }
}

// MARK: - Layout helper

/// A row of label/value pairs used by the listing detail facts grid.
struct FactRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(Brand.Font.eyebrow)
                .tracking(0.5)
                .foregroundStyle(Brand.Color.textSecondary)
            Text(value)
                .font(Brand.Font.bodyMedium(15, relativeTo: .subheadline))
                .foregroundStyle(Brand.Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
