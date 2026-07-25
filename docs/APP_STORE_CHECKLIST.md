# App Store submission checklist

Status against Apple's App Review Guidelines. ✅ = handled in this repo,
⚠️ = needs you (asset, account or business decision).

---

## The rejection that matters most: Guideline 4.2, Minimum Functionality

> "Your app should include features, content, and UI that elevate it beyond a
> repackaged website."

Apple **rejects webview wrappers of a website**, and a real-estate brokerage app
is a category reviewers see constantly. This is the single most likely reason a
"turn our site into an app" project fails review.

So this app is **fully native SwiftUI — there is no `WKWebView` anywhere.** It
does things the website cannot:

| Native capability | Where |
|---|---|
| Map-based property search with price annotations | `SearchView` / `ListingMapView` |
| Saved properties persisted on device, offline | `SavedListingsStore` |
| Native multi-criteria filtering and sorting | `FiltersView` |
| Tap-to-call, tap-to-email, native share sheet | throughout |
| Turn-by-turn handoff to Apple Maps | `ListingDetailView` |
| Full VoiceOver support and Dynamic Type | throughout |
| Pull-to-refresh against the live MLS feed | `SearchView`, `HomeView` |

Keep it that way. If a "just link the blog in a webview" request comes later,
that's the thing that reintroduces 4.2 risk.

---

## Privacy

| Item | Status |
|---|---|
| `PrivacyInfo.xcprivacy` present | ✅ `Support/PrivacyInfo.xcprivacy` |
| Required-reason API declared (UserDefaults, CA92.1) | ✅ |
| `NSPrivacyTracking` = false, no tracking domains | ✅ |
| Collected data types | ✅ empty — the app collects nothing |
| Location purpose string | ✅ `NSLocationWhenInUseUsageDescription` |
| Third-party SDK manifests | ✅ n/a — zero dependencies |
| Privacy policy URL reachable | ⚠️ verify `https://lanierproperties.net/privacy-policy/` resolves |

**App Privacy questionnaire in App Store Connect:** answer "Data Not Collected"
throughout — provided you don't add analytics later. The app has no account, no
server-side profile, and the contact form hands off to the user's own mail app
rather than posting anywhere.

If you later add a lead-capture form that POSTs to a server, this changes: you
must declare Contact Info, and adding accounts would trigger the
**account-deletion requirement (5.1.1(v))**.

---

## Configuration

| Item | Status |
|---|---|
| Launch screen (`UILaunchScreen`) | ✅ branded background, no advertising |
| Supported orientations | ✅ portrait + landscape |
| iPhone-only (`TARGETED_DEVICE_FAMILY = 1`) | ✅ permitted; it will still run letterboxed on iPad |
| ATS with no exceptions | ✅ all feeds must be HTTPS |
| `ITSAppUsesNonExemptEncryption = false` | ✅ skips the export questionnaire |
| No private APIs, no `UIWebView` | ✅ |
| Deployment target iOS 17 | ✅ |
| Bundle ID `net.lanierproperties.app` | ✅ register it in the Developer portal |
| App icon 1024×1024, no alpha | ⚠️ slot is empty — see `BRANDING.md` |
| Screenshots 6.9" and 6.5" | ⚠️ required at submission |

---

## Accessibility

| Item | Status |
|---|---|
| Dynamic Type on every text style (`relativeTo:`) | ✅ |
| VoiceOver labels on cards, buttons, map pins | ✅ |
| Decorative images hidden from VoiceOver | ✅ |
| Touch targets ≥ 44pt | ✅ buttons are 50pt |
| Dark mode | ✅ every colour has a dark variant |
| Contrast ≥ 4.5:1 body text | ⚠️ re-verify after you swap in the real palette |

---

## Real-estate specifics

| Item | Status |
|---|---|
| MLS attribution on listing detail | ✅ |
| IDX "deemed reliable but not guaranteed" disclaimer | ✅ on every listing surface |
| Equal Housing Opportunity statement | ✅ |
| Sold data not publicly browsable | ✅ default status filter |
| Feed refresh well inside 12 hours | ✅ 15-minute cache TTL |
| **MLS approval for a mobile app display** | ⚠️ confirm with MAAR — often a separate agreement from the website IDX |
| Broker licence number displayed | ⚠️ add to `BrandInfo` if TN/MS advertising rules require it |

Tennessee and Mississippi both have real-estate advertising rules about
displaying the firm name and licence status. Worth a five-minute check with your
principal broker before submitting.

---

## App Store Connect metadata

- **Name:** Lanier Properties (30 char limit)
- **Subtitle:** e.g. "West TN & North MS Real Estate"
- **Category:** Lifestyle (primary). Business is a reasonable secondary.
- **Age rating:** 4+
- **Support URL:** `https://lanierproperties.net/contact/` ⚠️ required
- **Marketing URL:** `https://lanierproperties.net/`
- **Privacy Policy URL:** ⚠️ required, must resolve
- **Copyright:** `2026 Lanier Properties`

**Demo account:** not needed — nothing is behind a login. Do use the review notes
field to say so, and to explain that listing data comes from the Memphis-area MLS
via an IDX feed.

**Digital Services Act:** App Store Connect requires a trader declaration for
distribution in the EU. A US brokerage with no EU business can decline EU
availability instead of completing it.

---

## Before you upload

```bash
xcodegen generate
open LanierProperties.xcodeproj
```

1. Set your team in `Configuration/Secrets.xcconfig` (`LANIER_DEVELOPMENT_TEAM`).
2. Add the app icon.
3. Point `IDX_PROVIDER` at the real feed — **do not ship with `mock`.** Sample
   listings presented as real inventory is both a review risk and a consumer
   problem.
4. Run the unit tests (`⌘U`).
5. Test on a real device: VoiceOver on, largest Dynamic Type, dark mode, and
   airplane mode to confirm the error states read sensibly.
6. Archive → Validate → Distribute.
