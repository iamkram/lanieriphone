import SwiftUI

/// Locally saved favourites. No account required and nothing leaves the device.
struct SavedListingsView: View {

    @Environment(SavedListingsStore.self) private var savedStore
    @State private var showClearConfirmation = false

    var body: some View {
        Group {
            if savedStore.saved.isEmpty {
                EmptyStateView(
                    title: "No saved properties yet",
                    message: "Tap the heart on any listing to keep it here. Saved properties stay on this device.",
                    systemImage: "heart"
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: Brand.Spacing.md) {
                        ForEach(savedStore.saved) { listing in
                            NavigationLink(value: listing) {
                                ListingCard(listing: listing)
                            }
                            .buttonStyle(.plain)
                        }
                        ListingDisclaimerView(showFairHousing: false)
                    }
                    .brandGutter()
                    .padding(.vertical, Brand.Spacing.md)
                }
            }
        }
        .background(Brand.Color.background)
        .navigationTitle("Saved")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: Listing.self) { listing in
            ListingDetailView(listing: listing)
        }
        .toolbar {
            if !savedStore.saved.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear", role: .destructive) { showClearConfirmation = true }
                }
            }
        }
        .confirmationDialog(
            "Remove all saved properties?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove All", role: .destructive) { savedStore.removeAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This only affects this device and can't be undone.")
        }
    }
}

#Preview {
    NavigationStack {
        SavedListingsView()
            .environment(SavedListingsStore())
    }
}
