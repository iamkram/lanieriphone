import Foundation

/// Company facts and marketing copy mirrored from lanierproperties.net.
///
/// Keeping these in one place means the app and the website can be kept in sync
/// without hunting through views. Values marked `// VERIFY` were reconstructed
/// from indexed search results rather than read off the live site — see
/// `docs/SITE_AUDIT.md` for provenance on every string in this file.
enum BrandInfo {

    // MARK: - Identity

    static let companyName = "Lanier Properties"
    /// The brokerage trades as "Lanier Realty" in several places on the site.
    static let brokerageName = "Lanier Realty"
    static let tagline = "Honesty. Hard work. Hometown values."
    static let foundedYear = 2024

    // MARK: - Contact (NAP)

    static let phoneDisplay = "731-203-8415"
    static let phoneDialable = "+17312038415"
    static let email = "info@lanierproperties.net"

    static let streetAddress = "114 S Main St"
    static let city = "Middleton"
    static let state = "TN"
    static let postalCode = "38052"

    static var addressSingleLine: String {
        "\(streetAddress), \(city), \(state) \(postalCode)"
    }

    static var addressMultiLine: String {
        "\(streetAddress)\n\(city), \(state) \(postalCode)"
    }

    /// Office coordinates for the contact-screen map. Refine to the exact rooftop
    /// pin if the website's embedded map uses a more precise location.
    static let officeLatitude = 35.0570   // VERIFY
    static let officeLongitude = -88.8930 // VERIFY

    // MARK: - Web

    static let websiteURL = URL(string: "https://lanierproperties.net/")!
    static let privacyPolicyURL = URL(string: "https://lanierproperties.net/privacy-policy/")!   // VERIFY
    static let termsURL = URL(string: "https://lanierproperties.net/terms/")!                     // VERIFY
    static let supportURL = URL(string: "https://lanierproperties.net/contact/")!

    /// Social profiles. Populate from the website footer; empty entries are hidden
    /// automatically by `ContactView`, so leaving one blank is safe.
    static let socialLinks: [SocialLink] = [
        SocialLink(name: "Facebook", systemImage: "person.2.fill", url: URL(string: "https://www.facebook.com/lanierrealtytn")), // VERIFY
        SocialLink(name: "Instagram", systemImage: "camera.fill", url: nil)                                                     // VERIFY
    ]

    struct SocialLink: Identifiable {
        let name: String
        let systemImage: String
        let url: URL?
        var id: String { name }
    }

    // MARK: - Service area

    /// Counties named on the About page.
    static let serviceCounties = [
        "Hardeman", "McNairy", "Hardin", "Tippah", "Alcorn", "Fayette"
    ]

    static let serviceRegionSummary = "West Tennessee and North Mississippi"

    // MARK: - Copy

    static let aboutHeadline = "Guiding families home since \(foundedYear)."

    static let aboutBody = """
    Lanier Realty has guided \(serviceRegionSummary) families home since \(foundedYear) — with local \
    insight, honest guidance, and care that extends well beyond closing day.

    We are a locally owned brokerage built on honesty, hard work, and hometown values. Our team of \
    seven dedicated agents combines local expertise with professional guidance to make every buying, \
    selling, or investing experience as smooth and rewarding as possible.
    """

    static let visionStatement = """
    Our vision is to become the most trusted and preferred real estate partner in Hardeman, McNairy, \
    Hardin, Tippah, Alcorn, and Fayette counties.
    """

    static let propertiesIntro = """
    From first-time home buyers to farms, land, and investment properties, our team of seven \
    experienced agents is ready to meet any real estate need.
    """

    // MARK: - Legal

    /// Shown on every listing surface. MLS participation agreements require
    /// attribution and a data-accuracy disclaimer on IDX displays.
    static let idxDisclaimer = """
    Listing data is provided courtesy of the participating MLS. Information is deemed reliable but is \
    not guaranteed accurate by the MLS or \(brokerageName). Listings displayed may be listed or sold \
    by a brokerage other than \(brokerageName). Data is refreshed periodically and may not reflect \
    the most current status of a property. All measurements and square footage are approximate.
    """

    static let fairHousingStatement = """
    \(brokerageName) is committed to the letter and spirit of U.S. policy for the achievement of equal \
    housing opportunity throughout the nation. We encourage and support an affirmative advertising and \
    marketing program in which there are no barriers to obtaining housing because of race, color, \
    religion, sex, handicap, familial status, or national origin.
    """
}
