import SwiftUI

// MARK: - Buy

/// The website's "Buy Home" page, including its FAQ.
struct BuyView: View {

    private static let faqs: [FAQ] = [
        FAQ(
            question: "How long does buying a home take?",
            answer: "From first consultation to closing, most buyers are in their new home within 30–90 days. "
                + "The search itself can take anywhere from a few days to a few months depending on your "
                + "criteria and market conditions. Once an offer is accepted, closing typically takes 30–45 "
                + "days to complete."
        ),
        FAQ(
            question: "How much do I need for a down payment?",
            answer: "Conventional loans typically require 3–20% down. FHA loans can be as low as 3.5% with "
                + "qualifying credit. VA and USDA loans may require no down payment at all — and much of our "
                + "service area is USDA eligible."
        ),
        FAQ(
            question: "Should I get pre-approved first?",
            answer: "Yes. A pre-approval tells you what you can comfortably afford and makes your offer far "
                + "stronger when you find the right place. We're glad to point you to lenders we trust locally."
        ),
        FAQ(
            question: "What does it cost me to work with a buyer's agent?",
            answer: "We'll walk you through how agent compensation works on any property you're considering, "
                + "in writing, before you make an offer. Give us a call and we'll explain it plainly."
        )
    ]

    private static let steps: [Step] = [
        Step(number: 1, title: "Talk with us", detail: "Tell us what you're looking for and what your timeline looks like."),
        Step(number: 2, title: "Get pre-approved", detail: "Know your budget before you fall in love with a place."),
        Step(number: 3, title: "Tour properties", detail: "We'll line up showings and give you the honest rundown on each one."),
        Step(number: 4, title: "Make an offer", detail: "We'll help you write a competitive offer and negotiate the terms."),
        Step(number: 5, title: "Inspections & appraisal", detail: "We coordinate the details and keep everything on schedule."),
        Step(number: 6, title: "Close", detail: "Sign, get your keys, and know we're still here afterward.")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Brand.Spacing.lg) {
                GuideHeader(
                    eyebrow: "Buying",
                    title: "Let's find the right place.",
                    message: "Hundreds of families have trusted \(BrandInfo.brokerageName) to find them the right "
                        + "home — and plenty of them have become lifelong friends."
                )

                StepList(title: "How It Works", steps: Self.steps)
                FAQList(faqs: Self.faqs)
                GuideCallToAction(title: "Ready to start looking?")
            }
            .brandGutter()
            .padding(.vertical, Brand.Spacing.md)
        }
        .background(Brand.Color.background)
        .navigationTitle("Buy a Home")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Sell

/// The website's selling page.
struct SellView: View {

    private static let steps: [Step] = [
        Step(number: 1, title: "Get a market opinion", detail: "We'll look at real comparable sales nearby and tell you what your property is realistically worth."),
        Step(number: 2, title: "Prepare and price", detail: "Small fixes and honest pricing do more for your bottom line than anything else."),
        Step(number: 3, title: "Market it properly", detail: "Photography, MLS syndication and local reach — land and farms get marketed differently than houses."),
        Step(number: 4, title: "Review offers", detail: "We'll explain every term, not just the number at the top."),
        Step(number: 5, title: "Close with confidence", detail: "We handle the coordination through to closing day.")
    ]

    private static let faqs: [FAQ] = [
        FAQ(
            question: "What is my property worth?",
            answer: "Give us a call and we'll prepare a comparative market analysis at no cost. For land and "
                + "farms we look at recent tract sales, road frontage, timber and tillable acreage — not just "
                + "a per-acre average."
        ),
        FAQ(
            question: "How long will it take to sell?",
            answer: "It depends on price, condition and property type. We'll give you a candid estimate up "
                + "front rather than an optimistic one."
        ),
        FAQ(
            question: "Do you handle land and farms?",
            answer: "Yes — farms, timber, recreational tracts and investment property are a large part of what "
                + "we do across West Tennessee and North Mississippi."
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Brand.Spacing.lg) {
                GuideHeader(
                    eyebrow: "Selling",
                    title: "Sell with people who know this ground.",
                    message: "From in-town homes to \(BrandInfo.serviceRegionSummary) farmland, we price it honestly "
                        + "and market it properly."
                )

                StepList(title: "How It Works", steps: Self.steps)
                FAQList(faqs: Self.faqs)
                GuideCallToAction(title: "Want to know what it's worth?")
            }
            .brandGutter()
            .padding(.vertical, Brand.Spacing.md)
        }
        .background(Brand.Color.background)
        .navigationTitle("Sell Your Property")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Shared guide components

struct FAQ: Identifiable, Hashable {
    let question: String
    let answer: String
    var id: String { question }
}

struct Step: Identifiable, Hashable {
    let number: Int
    let title: String
    let detail: String
    var id: Int { number }
}

struct GuideHeader: View {
    let eyebrow: String
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
            Text(eyebrow.uppercased())
                .font(Brand.Font.eyebrow)
                .tracking(1.2)
                .foregroundStyle(Brand.Color.primary)
            Text(title)
                .font(Brand.Font.pageTitle)
                .foregroundStyle(Brand.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(message)
                .font(Brand.Font.bodyText)
                .foregroundStyle(Brand.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct StepList: View {
    let title: String
    let steps: [Step]

    var body: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.md) {
            Text(title)
                .font(Brand.Font.sectionTitle)
                .foregroundStyle(Brand.Color.textPrimary)

            ForEach(steps) { step in
                HStack(alignment: .top, spacing: Brand.Spacing.md) {
                    Text(String(step.number))
                        .font(Brand.Font.bodySemibold(15, relativeTo: .subheadline))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Brand.Color.primary, in: Circle())
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.title)
                            .font(Brand.Font.cardTitle)
                            .foregroundStyle(Brand.Color.textPrimary)
                        Text(step.detail)
                            .font(Brand.Font.bodyText)
                            .foregroundStyle(Brand.Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Step \(step.number). \(step.title). \(step.detail)")
            }
        }
    }
}

/// Expandable FAQ list. `DisclosureGroup` gives us the accessibility behaviour
/// for free.
struct FAQList: View {
    let faqs: [FAQ]
    @State private var expanded: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
            Text("Common Questions")
                .font(Brand.Font.sectionTitle)
                .foregroundStyle(Brand.Color.textPrimary)
                .padding(.bottom, Brand.Spacing.xs)

            ForEach(faqs) { faq in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expanded.contains(faq.id) },
                        set: { isOpen in
                            if isOpen { expanded.insert(faq.id) } else { expanded.remove(faq.id) }
                        }
                    )
                ) {
                    Text(faq.answer)
                        .font(Brand.Font.bodyText)
                        .foregroundStyle(Brand.Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Brand.Spacing.xs)
                } label: {
                    Text(faq.question)
                        .font(Brand.Font.bodySemibold(16, relativeTo: .headline))
                        .foregroundStyle(Brand.Color.textPrimary)
                        .multilineTextAlignment(.leading)
                }
                .tint(Brand.Color.primary)
                .padding(Brand.Spacing.md)
                .background(Brand.Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous))
            }
        }
    }
}

struct GuideCallToAction: View {
    let title: String
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.md) {
            Text(title)
                .font(Brand.Font.sectionTitle)
                .foregroundStyle(Brand.Color.textPrimary)

            PrimaryButton(title: "Call \(BrandInfo.phoneDisplay)", systemImage: "phone.fill") {
                if let url = URL(string: "tel://\(BrandInfo.phoneDialable)") { openURL(url) }
            }

            NavigationLink {
                ContactView()
            } label: {
                Text("Send us a message")
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
        .padding(Brand.Spacing.lg)
        .background(Brand.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous))
    }
}

#Preview("Buy") {
    NavigationStack { BuyView() }
}

#Preview("Sell") {
    NavigationStack { SellView() }
}
