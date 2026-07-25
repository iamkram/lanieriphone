import SwiftUI
import UIKit
import MapKit

/// The website's "Contact" page: office details, a map, and a message form that
/// hands off to the user's mail app.
///
/// The form composes a `mailto:` message rather than posting to a server, so the
/// app collects and transmits no personal data itself — the message goes straight
/// from the customer's own mail account to the office.
struct ContactView: View {

    @Environment(\.openURL) private var openURL

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var message = ""
    @State private var showMailUnavailable = false

    private var canSend: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !message.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Brand.Spacing.lg) {
                header
                quickActions
                officeCard
                map
                form
                socialLinks
            }
            .brandGutter()
            .padding(.vertical, Brand.Spacing.md)
        }
        .background(Brand.Color.background)
        .navigationTitle("Contact")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .alert("Mail isn't set up", isPresented: $showMailUnavailable) {
            Button("Call the office") {
                if let url = URL(string: "tel://\(BrandInfo.phoneDialable)") { openURL(url) }
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text("We couldn't open your mail app. You can reach us at \(BrandInfo.phoneDisplay).")
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
            Text("We'd love to hear from you.")
                .font(Brand.Font.pageTitle)
                .foregroundStyle(Brand.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Call, email or stop by the office in \(BrandInfo.city). We answer our own phones.")
                .font(Brand.Font.bodyText)
                .foregroundStyle(Brand.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var quickActions: some View {
        VStack(spacing: Brand.Spacing.sm) {
            PrimaryButton(title: "Call \(BrandInfo.phoneDisplay)", systemImage: "phone.fill") {
                if let url = URL(string: "tel://\(BrandInfo.phoneDialable)") { openURL(url) }
            }
            SecondaryButton(title: "Email Us", systemImage: "envelope.fill") {
                if let url = URL(string: "mailto:\(BrandInfo.email)") { openURL(url) }
            }
        }
    }

    private var officeCard: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.md) {
            ContactRow(icon: "building.2.fill", label: "Office", value: BrandInfo.addressMultiLine)
            ContactRow(icon: "phone.fill", label: "Phone", value: BrandInfo.phoneDisplay)
            ContactRow(icon: "envelope.fill", label: "Email", value: BrandInfo.email)
            ContactRow(icon: "globe", label: "Web", value: "lanierproperties.net")
        }
        .brandCard(padding: Brand.Spacing.lg)
    }

    private var map: some View {
        let coordinate = CLLocationCoordinate2D(
            latitude: BrandInfo.officeLatitude,
            longitude: BrandInfo.officeLongitude
        )

        return VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
            Map(initialPosition: .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))) {
                Marker(BrandInfo.companyName, coordinate: coordinate)
                    .tint(Brand.Color.primary)
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.image, style: .continuous))
            .allowsHitTesting(false)
            .accessibilityLabel("Map showing the office at \(BrandInfo.addressSingleLine)")

            Button {
                let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
                item.name = BrandInfo.companyName
                item.openInMaps()
            } label: {
                Label("Get directions", systemImage: "arrow.triangle.turn.up.right.circle")
                    .font(Brand.Font.bodyMedium(15, relativeTo: .subheadline))
                    .foregroundStyle(Brand.Color.primary)
            }
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.md) {
            Text("Send Us a Message")
                .font(Brand.Font.sectionTitle)
                .foregroundStyle(Brand.Color.textPrimary)

            LabeledField(title: "Name", text: $name, contentType: .name)
            LabeledField(title: "Email", text: $email, contentType: .emailAddress, keyboard: .emailAddress)
            LabeledField(title: "Phone (optional)", text: $phone, contentType: .telephoneNumber, keyboard: .phonePad)

            VStack(alignment: .leading, spacing: Brand.Spacing.xs) {
                Text("How can we help?")
                    .font(Brand.Font.eyebrow)
                    .tracking(0.5)
                    .foregroundStyle(Brand.Color.textSecondary)
                TextEditor(text: $message)
                    .font(Brand.Font.bodyText)
                    .frame(minHeight: 120)
                    .padding(Brand.Spacing.sm)
                    .background(Brand.Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.button, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Brand.Radius.button, style: .continuous)
                            .stroke(Brand.Color.divider, lineWidth: 1)
                    )
                    .accessibilityLabel("Your message")
            }

            PrimaryButton(title: "Send Message", systemImage: "paperplane.fill") {
                composeEmail()
            }
            .opacity(canSend ? 1 : 0.5)
            .disabled(!canSend)

            Text("Tapping Send opens your mail app with the message ready to go. Nothing is sent from the app itself.")
                .font(Brand.Font.body(12, relativeTo: .caption))
                .foregroundStyle(Brand.Color.textSecondary)
        }
    }

    @ViewBuilder
    private var socialLinks: some View {
        let links = BrandInfo.socialLinks.filter { $0.url != nil }
        if !links.isEmpty {
            VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                Text("Follow Along")
                    .font(Brand.Font.sectionTitle)
                    .foregroundStyle(Brand.Color.textPrimary)

                HStack(spacing: Brand.Spacing.md) {
                    ForEach(links) { link in
                        Button {
                            if let url = link.url { openURL(url) }
                        } label: {
                            Label(link.name, systemImage: link.systemImage)
                                .font(Brand.Font.bodyMedium(15, relativeTo: .subheadline))
                                .foregroundStyle(Brand.Color.primary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func composeEmail() {
        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)
        let body = """
        \(message)

        —
        \(name)
        \(email)
        \(trimmedPhone.isEmpty ? "" : trimmedPhone)
        """

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = BrandInfo.email
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Website inquiry from \(name)"),
            URLQueryItem(name: "body", value: body)
        ]

        guard let url = components.url else {
            showMailUnavailable = true
            return
        }

        openURL(url) { accepted in
            if !accepted { showMailUnavailable = true }
        }
    }
}

// MARK: - Supporting views

private struct ContactRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: Brand.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Brand.Color.primary)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(Brand.Font.eyebrow)
                    .tracking(0.5)
                    .foregroundStyle(Brand.Color.textSecondary)
                Text(value)
                    .font(Brand.Font.bodyText)
                    .foregroundStyle(Brand.Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

private struct LabeledField: View {
    let title: String
    @Binding var text: String
    var contentType: UITextContentType?
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.xs) {
            Text(title)
                .font(Brand.Font.eyebrow)
                .tracking(0.5)
                .foregroundStyle(Brand.Color.textSecondary)

            TextField(title, text: $text)
                .font(Brand.Font.bodyText)
                .textContentType(contentType)
                .keyboardType(keyboard)
                .autocorrectionDisabled(keyboard == .emailAddress)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                .padding(Brand.Spacing.md)
                .background(Brand.Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.button, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Brand.Radius.button, style: .continuous)
                        .stroke(Brand.Color.divider, lineWidth: 1)
                )
                .accessibilityLabel(title)
        }
    }
}

#Preview {
    NavigationStack { ContactView() }
}
