import Foundation

/// A member of the brokerage, mirroring the website's "Our Team" page.
struct Agent: Identifiable, Hashable, Codable, Sendable {
    let id: String
    var name: String
    var title: String
    /// Name of the image in `Assets.xcassets`. Falls back to initials when the
    /// asset is missing, so the screen never shows a broken image.
    var photoAssetName: String?
    var phone: String?
    var email: String?
    var licenseNumber: String?
    var licensedIn: [String]
    var bio: String

    var phoneDialable: String? {
        phone.map { "+1" + $0.filter(\.isNumber) }
    }

    var initials: String {
        name.split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }
}

/// The team roster.
///
/// The website states the brokerage has seven agents; three are confirmed by name
/// below. Fill in the remaining four from the "Our Team" page — the screen adapts
/// to however many entries are present. See `docs/SITE_AUDIT.md`.
enum AgentDirectory {

    static let all: [Agent] = [
        Agent(
            id: "karen-lanier",
            name: "Karen Lanier",
            title: "Broker",
            photoAssetName: "agent-karen-lanier",
            phone: nil,
            email: BrandInfo.email,
            licenseNumber: nil,
            licensedIn: ["Tennessee", "Mississippi"],
            bio: "An experienced real estate professional licensed in Tennessee and Mississippi since 2019. "
                + "Karen spent thirty years as an educator before moving into real estate, and she brings the "
                + "same patience and clear explanation to guiding clients through a transaction."
        ),
        Agent(
            id: "lane-lanier",
            name: "Lane Lanier",
            title: "Affiliate Broker",
            photoAssetName: "agent-lane-lanier",
            phone: nil,
            email: BrandInfo.email,
            licenseNumber: nil,
            licensedIn: ["Tennessee"],
            bio: "Lane works with buyers and sellers across West Tennessee, with particular depth in farms, "
                + "land and recreational tracts."
        ),
        Agent(
            id: "christi-mccaslin",
            name: "Christi McCaslin",
            title: "REALTOR®, Affiliate Broker",
            photoAssetName: "agent-christi-mccaslin",
            phone: "731-518-5261",
            email: "christimccaslin.re@gmail.com",
            licenseNumber: nil,
            licensedIn: ["Tennessee"],
            bio: "A dedicated REALTOR® and Affiliate Broker serving Hardeman, Fayette, Shelby, McNairy, Hardin "
                + "and the surrounding West Tennessee counties."
        )
    ]

    static func agent(named name: String) -> Agent? {
        all.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }
}
