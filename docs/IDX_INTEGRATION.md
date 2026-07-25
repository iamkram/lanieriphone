# Connecting the MLS / IDX feed

The app talks to exactly one protocol — `ListingService` — and every screen goes
through it. Swapping feeds is a configuration change, not a code change.

```
SwiftUI views → ListingRepository → ListingService (protocol)
                                     ├── RESOWebAPIClient      (RESO Web API / OData)
                                     ├── IDXBrokerClient       (idxbroker.com)
                                     ├── SimplyRETSClient      (SimplyRETS)
                                     ├── ProxyListingClient    (your own endpoint) ← recommended
                                     └── MockListingService    (bundled sample data)
```

`IDXConfiguration.fromBundle()` reads Info.plist at launch and builds the right
adapter. If a provider is selected but its credentials are missing, it falls back
to sample data rather than crashing, and the More tab shows why.

---

## Before you can finish this: two things I need from you

1. **Which IDX vendor is behind lanierproperties.net.** The listing permalinks
   (`/properties/listing/MemphisTN/10208555/Middleton/HIGHWAY-57-HWY`) look like
   IDX Broker, but I could not reach the site to confirm — see `SITE_AUDIT.md`.
   The fastest way to check: WordPress Admin → Plugins, or view source on a
   listing page and look for `idxbroker.com`, `ihomefinder`, `showcaseidx`,
   `simplyrets` or `realtyna`.
2. **Credentials** for that vendor, plus your **MLS office key** (used to select
   "Our Properties" rather than the whole regional feed).

Also worth confirming with the Memphis Area Association of REALTORS®: most MLS
IDX agreements require a **separate approval for a mobile app** display, and some
prohibit shipping feed credentials inside a client binary at all. That constraint
is the reason for the proxy option below.

---

## Setup

### 1. Credentials file (never committed)

```bash
cp Configuration/Secrets.xcconfig.example Configuration/Secrets.xcconfig
```

`Configuration/Secrets.xcconfig` is in `.gitignore`. It overrides the defaults in
`Debug.xcconfig` / `Release.xcconfig`, which are included optionally via
`#include?`.

> **xcconfig gotcha:** `//` starts a comment, so a URL must be escaped as
> `https:/$()/example.com/path`. The committed `Release.xcconfig` shows the form.

### 2. Pick a provider

#### Option A — Proxy (recommended for the App Store)

```
IDX_PROVIDER = proxy
IDX_BASE_URL = https:/$()/lanierproperties.net/wp-json/lanier-idx/v1
IDX_API_KEY  = <optional shared token>
```

A key compiled into an iOS binary is extractable by anyone who downloads the app.
Putting a thin endpoint on the existing WordPress site keeps the MLS credentials
server-side, lets you honour the feed's rate limits and caching rules in one
place, and means rotating a key doesn't require an App Store release.

The endpoint needs three routes:

| Route | Returns |
|---|---|
| `GET /listings?limit&cursor&q&minPrice&maxPrice&minBeds&minBaths&minAcres&maxAcres&city&propertyType&status&sort` | `{ "listings": [...], "nextCursor": "...", "totalCount": 123 }` |
| `GET /listings/{id}` | a single listing object |
| `GET /listings/office?limit&cursor` | the brokerage's own listings, same page shape |
| `GET /cities` | `["Middleton", "Bolivar", ...]` |

Each listing object matches `Listing` in `Models/Listing.swift` — the same JSON
keys, ISO-8601 dates. Because `Listing` is `Codable`, the proxy adapter needs no
mapping code at all.

#### Option B — RESO Web API direct

```
IDX_PROVIDER                = reso
IDX_BASE_URL                = https:/$()/api.bridgedataoutput.com/api/v2/OData/<dataset>
IDX_API_KEY                 = <bearer token>
IDX_ORIGINATING_SYSTEM_NAME = MemphisTN
IDX_OFFICE_KEY              = <your MLS office key>
```

Works with Bridge Interactive, MLS Grid, Trestle and Spark/FlexMLS. The adapter
queries the `Property` resource with `$filter`/`$orderby`/`$top`/`$skip` and
expands `Media` for photos.

#### Option C — IDX Broker

```
IDX_PROVIDER                = idxbroker
IDX_API_KEY                 = <Partners API access key>
IDX_ORIGINATING_SYSTEM_NAME = <your IDX Broker MLS id, e.g. a001>
```

Note IDX Broker's API is rate-limited per hour and its search endpoint doesn't
paginate server-side, so the adapter fetches a window and pages over it locally.

#### Option D — SimplyRETS

```
IDX_PROVIDER = simplyrets
IDX_API_KEY  = <apiKey>:<apiSecret>
```

#### Option E — Sample data (the default)

```
IDX_PROVIDER = mock
```

A fresh clone builds and runs with realistic sample listings and no credentials.

---

## Adding a different vendor

Conform to `ListingService`, map the vendor's payload into `Listing`, then add a
case to `IDXProvider` and `IDXConfiguration.makeService()`. Nothing in the UI
changes. `RESOWebAPIClient` is the clearest example to copy — its mapping is a
direct translation of the RESO Data Dictionary.

Reuse `IDXHTTPClient` for the transport; it centralises timeouts, exponential
backoff on 429/5xx, and mapping HTTP status codes onto `ListingServiceError`.

---

## Compliance notes baked into the app

- **Attribution** — `ListingDetailView` names the listing brokerage and the data
  source. Required when the listing belongs to another office.
- **Disclaimer** — `ListingDisclaimerView` appears on every screen showing feed
  data, with the "deemed reliable but not guaranteed" language.
- **Fair housing** — the equal-opportunity statement ships with the disclaimer
  and in full under More → MLS & Fair Housing.
- **Refresh cadence** — `IDXConfiguration.cacheTTL` defaults to 15 minutes, well
  inside the 12-hour refresh most IDX agreements require.
- **Status filtering** — only `Active`, `Coming Soon`, `Active Under Contract` and
  `Pending` are browsable by default; sold data is not exposed publicly.

Check the exact required disclaimer wording with your MLS — it varies by board,
and the text in `BrandInfo.idxDisclaimer` is a reasonable generic version, not
MAAR's official wording.
