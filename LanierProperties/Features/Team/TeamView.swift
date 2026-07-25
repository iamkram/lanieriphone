import SwiftUI
import UIKit

/// The website's "Our Team" page.
struct TeamView: View {

    private let agents = AgentDirectory.all

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Brand.Spacing.lg) {
                intro

                ForEach(agents) { agent in
                    NavigationLink(value: agent) {
                        AgentCard(agent: agent)
                    }
                    .buttonStyle(.plain)
                }

                joinUs
            }
            .brandGutter()
            .padding(.vertical, Brand.Spacing.md)
        }
        .background(Brand.Color.background)
        .navigationTitle("Our Team")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: Agent.self) { agent in
            AgentDetailView(agent: agent)
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
            Text("Local expertise, honest guidance.")
                .font(Brand.Font.sectionTitle)
                .foregroundStyle(Brand.Color.textPrimary)
            Text(BrandInfo.propertiesIntro)
                .font(Brand.Font.bodyText)
                .foregroundStyle(Brand.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var joinUs: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
            Text("Interested in joining us?")
                .font(Brand.Font.cardTitle)
                .foregroundStyle(Brand.Color.textPrimary)
            Text("We're always glad to talk with agents who share our values.")
                .font(Brand.Font.bodyText)
                .foregroundStyle(Brand.Color.textSecondary)
            CallOfficeButton()
                .padding(.top, Brand.Spacing.xs)
        }
        .padding(Brand.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous))
    }
}

// MARK: - Agent card

struct AgentCard: View {
    let agent: Agent

    var body: some View {
        HStack(spacing: Brand.Spacing.md) {
            AgentAvatar(agent: agent, size: 72)

            VStack(alignment: .leading, spacing: 3) {
                Text(agent.name)
                    .font(Brand.Font.cardTitle)
                    .foregroundStyle(Brand.Color.textPrimary)
                Text(agent.title)
                    .font(Brand.Font.caption)
                    .foregroundStyle(Brand.Color.textSecondary)
                if !agent.licensedIn.isEmpty {
                    Text("Licensed in \(agent.licensedIn.joined(separator: " & "))")
                        .font(Brand.Font.body(12, relativeTo: .caption))
                        .foregroundStyle(Brand.Color.textSecondary.opacity(0.85))
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Brand.Color.textSecondary.opacity(0.6))
        }
        .brandCard()
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens \(agent.name)'s profile")
    }
}

/// Photo when available, initials when not — so a missing asset degrades neatly.
struct AgentAvatar: View {
    let agent: Agent
    var size: CGFloat = 72

    private var hasPhoto: Bool {
        guard let name = agent.photoAssetName else { return false }
        return UIImage(named: name) != nil
    }

    var body: some View {
        Group {
            if hasPhoto, let name = agent.photoAssetName {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Brand.Color.primary.opacity(0.14)
                    Text(agent.initials)
                        .font(Brand.Font.bodySemibold(size * 0.33, relativeTo: .title3))
                        .foregroundStyle(Brand.Color.primary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}

// MARK: - Detail

struct AgentDetailView: View {
    let agent: Agent

    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Brand.Spacing.lg) {
                VStack(alignment: .center, spacing: Brand.Spacing.md) {
                    AgentAvatar(agent: agent, size: 128)
                    Text(agent.name)
                        .font(Brand.Font.pageTitle)
                        .foregroundStyle(Brand.Color.textPrimary)
                    Text(agent.title)
                        .font(Brand.Font.bodyText)
                        .foregroundStyle(Brand.Color.textSecondary)
                }
                .frame(maxWidth: .infinity)

                Text(agent.bio)
                    .font(Brand.Font.bodyText)
                    .foregroundStyle(Brand.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !agent.licensedIn.isEmpty {
                    FactRow(label: "Licensed In", value: agent.licensedIn.joined(separator: ", "))
                }
                if let license = agent.licenseNumber {
                    FactRow(label: "License #", value: license)
                }

                VStack(spacing: Brand.Spacing.sm) {
                    if let phone = agent.phone, let dialable = agent.phoneDialable {
                        PrimaryButton(title: "Call \(phone)", systemImage: "phone.fill") {
                            if let url = URL(string: "tel://\(dialable)") { openURL(url) }
                        }
                    }
                    if let email = agent.email {
                        SecondaryButton(title: "Email \(agent.name.split(separator: " ").first.map(String.init) ?? "agent")",
                                        systemImage: "envelope.fill") {
                            if let url = URL(string: "mailto:\(email)") { openURL(url) }
                        }
                    }
                }
            }
            .brandGutter()
            .padding(.vertical, Brand.Spacing.lg)
        }
        .background(Brand.Color.background)
        .navigationTitle(agent.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TeamView()
    }
}
