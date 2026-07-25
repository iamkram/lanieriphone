# Lanier Properties — iPhone app

A native SwiftUI iPhone app for [Lanier Properties](https://lanierproperties.net/)
(Lanier Realty), Middleton, TN — mirroring the website's pages and branding, with
MLS listings ingested through a pluggable IDX layer.

## Read this first

Two things are **not finished**, and both need input only you can provide:

1. **The website could not be reached from the build environment** — the network
   policy blocked the domain and every fetch tool returned 403, including archive
   mirrors. Page structure and copy were reconstructed from search indexes; the
   **logo, fonts, exact colours and photography could not be obtained.** The app
   ships with a placeholder palette and system-font fallback and renders
   correctly, but it does not yet look pixel-identical to the site.
   → `docs/BRANDING.md` (a three-file swap), `docs/SITE_AUDIT.md` (what's verified).

2. **The IDX vendor and credentials are unknown.** Four adapters are implemented;
   pick one and add credentials. → `docs/IDX_INTEGRATION.md`.

Until then the app runs on realistic bundled sample data.

**This code has not been compiled.** The build environment is Linux with no Swift
toolchain or Xcode, so it was written to compile on a Mac but not verified there.
Expect to fix a small number of compiler diagnostics on first build.

## Quick start

```bash
brew install xcodegen          # once
xcodegen generate
open LanierProperties.xcodeproj
```

Builds and runs immediately with sample listings — no credentials needed.

## Layout

```
LanierProperties/
├── App/          entry point, tab navigation, saved-listings store
├── Brand/        Brand.swift (colours, fonts, spacing) · BrandInfo.swift (copy, NAP, legal)
├── Models/       Listing, Agent, SearchFilters
├── IDX/          ListingService protocol + 5 adapters + repository   ← MLS ingestion
├── Features/     Home · Search · ListingDetail · Saved · Team · About · Guides · Contact · More
├── Components/   ListingCard, shared views
└── Support/      Info.plist, PrivacyInfo.xcprivacy, Assets.xcassets
```

## Screens

| Tab | Covers |
|---|---|
| Home | Hero, featured properties, who we are, service area |
| Search | MLS search with filters, sort, and a list/map toggle |
| Saved | Favourites, stored on device, no account |
| Our Team | Agent roster and profiles |
| More | Buy, Sell, About, Contact, legal disclosures, feed status |

Every website page maps to a screen — the table is in `docs/SITE_AUDIT.md`.

## MLS / IDX

Everything goes through one protocol, so the feed is a config change:

```
views → ListingRepository → ListingService
                             ├── RESOWebAPIClient   (RESO Web API / OData — Bridge, MLS Grid, Trestle, Spark)
                             ├── IDXBrokerClient    (idxbroker.com)
                             ├── SimplyRETSClient
                             ├── ProxyListingClient (your own endpoint — recommended for release)
                             └── MockListingService (sample data — the default)
```

Credentials live in `Configuration/Secrets.xcconfig`, which is git-ignored.
Nothing secret is committed.

For an App Store release, prefer the **proxy** option: an API key inside an app
binary is extractable by anyone who downloads it, and most MLS IDX agreements
prohibit distributing feed credentials that way.

## App Store readiness

Native throughout — **no webview** — which is what keeps it clear of guideline
4.2 (Apple rejects repackaged websites). Privacy manifest, launch screen, ATS,
encryption declaration, Dynamic Type, VoiceOver and dark mode are all in place;
the app icon and screenshots are the remaining blockers.

Full status, including the MLS/fair-housing obligations: `docs/APP_STORE_CHECKLIST.md`.

## Tests

```bash
xcodebuild test -scheme LanierProperties -destination 'platform=iOS Simulator,name=iPhone 16'
```

Covers listing formatting edge cases (land with no bedrooms, half baths,
un-geocoded 0,0 coordinates), filter and pagination behaviour, and the
credential-missing fallback path.

## Docs

| File | What's in it |
|---|---|
| `docs/SITE_AUDIT.md` | Page inventory, extracted brand facts, and exactly what is unverified |
| `docs/BRANDING.md` | How to make the app match the site: colours, fonts, images, icon |
| `docs/IDX_INTEGRATION.md` | Feed setup per vendor, proxy endpoint spec, compliance notes |
| `docs/APP_STORE_CHECKLIST.md` | Guideline-by-guideline status and submission metadata |
