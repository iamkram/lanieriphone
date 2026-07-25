import SwiftUI

/// Catch-all tab holding the remaining website pages plus app-level items.
struct MoreView: View {

    @Environment(\.openURL) private var openURL
    @Environment(\.idxConfiguration) private var configuration

    var body: some View {
        List {
            Section("Working With Us") {
                NavigationLink { BuyView() } label: {
                    Label("Buy a Home", systemImage: "key.fill")
                }
                NavigationLink { SellView() } label: {
                    Label("Sell Your Property", systemImage: "signpost.right.fill")
                }
                NavigationLink { AboutView() } label: {
                    Label("About Us", systemImage: "info.circle.fill")
                }
                NavigationLink { ContactView() } label: {
                    Label("Contact", systemImage: "envelope.fill")
                }
            }

            Section("Get In Touch") {
                Button {
                    if let url = URL(string: "tel://\(BrandInfo.phoneDialable)") { openURL(url) }
                } label: {
                    Label(BrandInfo.phoneDisplay, systemImage: "phone.fill")
                }
                Button {
                    if let url = URL(string: "mailto:\(BrandInfo.email)") { openURL(url) }
                } label: {
                    Label(BrandInfo.email, systemImage: "envelope")
                }
                Button {
                    openURL(BrandInfo.websiteURL)
                } label: {
                    Label("lanierproperties.net", systemImage: "safari")
                }
            }

            Section("Legal") {
                Button { openURL(BrandInfo.privacyPolicyURL) } label: {
                    Label("Privacy Policy", systemImage: "lock.shield")
                }
                Button { openURL(BrandInfo.termsURL) } label: {
                    Label("Terms of Use", systemImage: "doc.text")
                }
                NavigationLink { DisclosuresView() } label: {
                    Label("MLS & Fair Housing", systemImage: "house.circle")
                }
            }

            Section {
                LabeledContent("Version", value: Self.versionString)
                LabeledContent("Listing data", value: configuration.statusDescription)
            } header: {
                Text("App")
            } footer: {
                Text("\(BrandInfo.companyName) · \(BrandInfo.addressSingleLine)")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("More")
        .navigationBarTitleDisplayMode(.large)
    }

    private static var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}

/// Full text of the MLS and fair-housing disclosures, reachable from the app
/// rather than only via a web link — required reading that shouldn't depend on
/// a network connection.
struct DisclosuresView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Brand.Spacing.lg) {
                VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                    Text("Listing Data")
                        .font(Brand.Font.sectionTitle)
                        .foregroundStyle(Brand.Color.textPrimary)
                    Text(BrandInfo.idxDisclaimer)
                        .font(Brand.Font.bodyText)
                        .foregroundStyle(Brand.Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                    Text("Equal Housing Opportunity")
                        .font(Brand.Font.sectionTitle)
                        .foregroundStyle(Brand.Color.textPrimary)
                    Text(BrandInfo.fairHousingStatement)
                        .font(Brand.Font.bodyText)
                        .foregroundStyle(Brand.Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                    Text("Your Privacy")
                        .font(Brand.Font.sectionTitle)
                        .foregroundStyle(Brand.Color.textPrimary)
                    Text("""
                    This app does not require an account and does not collect personal information. Saved \
                    properties are stored only on your device and are removed when you delete the app. \
                    Messages you send through the Contact screen are composed in your own mail app and sent \
                    from your account directly to our office.
                    """)
                        .font(Brand.Font.bodyText)
                        .foregroundStyle(Brand.Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .brandGutter()
            .padding(.vertical, Brand.Spacing.lg)
        }
        .background(Brand.Color.background)
        .navigationTitle("Disclosures")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { MoreView() }
}
