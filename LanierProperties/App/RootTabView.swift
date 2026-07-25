import SwiftUI

/// Top-level navigation.
///
/// The five tabs cover every page on lanierproperties.net: Home, Search
/// (Our Properties / MLS search), Saved, Team (Our Team + About) and More
/// (Buy, Sell, Contact and legal).
struct RootTabView: View {

    @State private var selection: Tab = .home

    enum Tab: Hashable {
        case home, search, saved, team, more
    }

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                HomeView(onSeeAllListings: { selection = .search })
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(Tab.home)

            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(Tab.search)

            NavigationStack {
                SavedListingsView()
            }
            .tabItem {
                Label("Saved", systemImage: "heart")
            }
            .tag(Tab.saved)

            NavigationStack {
                TeamView()
            }
            .tabItem {
                Label("Our Team", systemImage: "person.2")
            }
            .tag(Tab.team)

            NavigationStack {
                MoreView()
            }
            .tabItem {
                Label("More", systemImage: "ellipsis")
            }
            .tag(Tab.more)
        }
    }
}

#Preview {
    RootTabView()
        .environment(ListingRepository(service: MockListingService()))
        .environment(SavedListingsStore())
}
