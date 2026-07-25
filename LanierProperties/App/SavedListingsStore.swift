import Foundation
import Observation

/// Favourites, stored locally on device.
///
/// Deliberately local-only: with no account and no server-side profile, the app
/// collects no personal data, which keeps the App Privacy questionnaire simple
/// and removes the account-deletion requirement of App Store guideline 5.1.1(v).
@Observable
@MainActor
final class SavedListingsStore {

    private(set) var saved: [Listing] = []

    private let defaultsKey = "saved_listings_v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    var savedIDs: Set<String> { Set(saved.map(\.id)) }

    func isSaved(_ listing: Listing) -> Bool {
        savedIDs.contains(listing.id)
    }

    func toggle(_ listing: Listing) {
        if isSaved(listing) {
            saved.removeAll { $0.id == listing.id }
        } else {
            saved.insert(listing, at: 0)
        }
        persist()
    }

    func remove(atOffsets offsets: IndexSet) {
        saved.remove(atOffsets: offsets)
        persist()
    }

    func removeAll() {
        saved.removeAll()
        persist()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = defaults.data(forKey: defaultsKey) else { return }
        // A decode failure means the stored shape predates the current model;
        // dropping it is preferable to crashing on launch.
        saved = (try? JSONDecoder().decode([Listing].self, from: data)) ?? []
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(saved) else { return }
        defaults.set(data, forKey: defaultsKey)
    }
}
