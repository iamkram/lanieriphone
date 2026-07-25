import SwiftUI

/// The website's "About" page.
struct AboutView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Brand.Spacing.lg) {
                Image("about-office")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.image, style: .continuous))
                    .accessibilityHidden(true)

                Text(BrandInfo.aboutHeadline)
                    .font(Brand.Font.pageTitle)
                    .foregroundStyle(Brand.Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(BrandInfo.aboutBody)
                    .font(Brand.Font.bodyText)
                    .foregroundStyle(Brand.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                visionCard
                valuesSection
                serviceAreaSection

                NavigationLink {
                    TeamView()
                } label: {
                    Text("Meet the team")
                        .font(Brand.Font.bodySemibold(16, relativeTo: .headline))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Brand.Color.primary, in: RoundedRectangle(cornerRadius: Brand.Radius.button, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .brandGutter()
            .padding(.vertical, Brand.Spacing.md)
        }
        .background(Brand.Color.background)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var visionCard: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
            Text("Our Vision")
                .font(Brand.Font.eyebrow)
                .tracking(1.2)
                .foregroundStyle(Brand.Color.primary)
            Text(BrandInfo.visionStatement)
                .font(Brand.Font.body(17, relativeTo: .body))
                .foregroundStyle(Brand.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Brand.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.Color.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous))
    }

    private var valuesSection: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.md) {
            Text("What We Stand For")
                .font(Brand.Font.sectionTitle)
                .foregroundStyle(Brand.Color.textPrimary)

            ValueRow(icon: "hand.raised.fill",
                     title: "Honesty",
                     detail: "Straight answers, even when they aren't the easy ones.")
            ValueRow(icon: "hammer.fill",
                     title: "Hard Work",
                     detail: "We do the legwork so a move feels manageable.")
            ValueRow(icon: "house.fill",
                     title: "Hometown Values",
                     detail: "We live here too, and we care how it goes for our neighbours.")
        }
    }

    private var serviceAreaSection: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
            Text("Counties We Serve")
                .font(Brand.Font.sectionTitle)
                .foregroundStyle(Brand.Color.textPrimary)
            Text(BrandInfo.serviceCounties.map { "\($0) County" }.joined(separator: " · "))
                .font(Brand.Font.bodyText)
                .foregroundStyle(Brand.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ValueRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: Brand.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Brand.Color.primary)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Brand.Font.cardTitle)
                    .foregroundStyle(Brand.Color.textPrimary)
                Text(detail)
                    .font(Brand.Font.bodyText)
                    .foregroundStyle(Brand.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack { AboutView() }
}
