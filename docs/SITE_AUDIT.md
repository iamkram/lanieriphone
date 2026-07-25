# Website audit — lanierproperties.net

## How this audit was produced, and its limits

**The site could not be fetched from this build environment.** This was
confirmed at every layer, including with a real headless Chromium browser:

1. The agent proxy refused `CONNECT lanierproperties.net:443` with a 403.
2. Bypassing the proxy entirely still failed. DNS resolves
   (`209.59.155.148`) and TCP 443 connects, but the response is a synthetic
   403 from a transparent egress filter:

   ```
   HTTP/2 403
   x-deny-reason: host_not_allowed

   Host not in allowlist: lanierproperties.net.
   Add this host to your network egress settings to allow access.
   ```

3. Headless Chromium (Playwright) gets the same 403. The browser itself works —
   it loads allowlisted hosts fine — so this is policy, not tooling.
4. Every mirror and reader proxy is blocked the same way: `web.archive.org`,
   `archive.org`, `r.jina.ai`, `api.allorigins.win`, `corsproxy.io`,
   `cachedview.nl`, even `www.google.com`.

**To unblock:** add `lanierproperties.net` (and `www.lanierproperties.net`) to
the environment's network egress allowlist — the environment's network policy is
chosen by whoever created it. See
<https://code.claude.com/docs/en/claude-code-on-the-web>. Once the site loads, a
second pass may need the CDN host that serves its images and fonts.

**Or, without changing anything:** run `scripts/extract-branding.sh` on any
machine that can reach the site. It pulls the colours, fonts, logo, images and
page text into `branding-export/`.

Everything below was therefore reconstructed from **search-engine indexes** of the
site. That is reliable for page structure and body copy, and unreliable for
anything visual.

### What is confirmed

| Item | Source |
|---|---|
| Page list and URLs | Indexed page titles |
| Company name, phone, email, address | Indexed page content, cross-checked against Yelp and Homes.com |
| Founded 2024, seven agents, service counties | About page copy |
| Buy-page FAQ answers (timelines, down payments) | Buy page copy |
| Listing URL pattern and MLS identifier | An indexed listing permalink |
| Agent names | Our Team page plus Homes.com/Facebook profiles |

### What is NOT confirmed — needs your input

- **Logo** — no file obtained.
- **Fonts** — the actual typefaces are unknown. `Brand.swift` currently names
  Playfair Display + Inter as stand-ins and **falls back to system fonts**, so the
  app renders correctly either way.
- **Exact colours** — the palette in `Assets.xcassets/Colors` is a placeholder.
- **Photography** — no hero, office or agent images obtained.
- **Four of the seven agents** — only three are named in the index.
- **Social links, privacy-policy and terms URLs** — guessed; marked `// VERIFY`
  in `BrandInfo.swift`.
- **Which IDX vendor the site uses** — inferred as likely IDX Broker from the URL
  shape, but not proven. This is why the app ships adapters for four feed types.

Every uncertain value in code carries a `// VERIFY` comment. `docs/BRANDING.md`
explains how to replace them, and nothing needs a code change beyond
`Brand.swift`, `BrandInfo.swift` and the asset catalog.

---

## Page inventory and where each one went in the app

| Website page | App destination |
|---|---|
| `/` (Home) | **Home** tab — `HomeView` |
| `/our-properties/` | **Home** featured carousel + **Search** tab |
| `/properties/listing/{mls}/{id}/{city}/{slug}` | `ListingDetailView` |
| `/about/` | `AboutView` (More tab, and linked from Home) |
| `/our-team/` | **Our Team** tab — `TeamView` / `AgentDetailView` |
| `/buy-home-middleton-tn/` | `BuyView` (More tab) |
| Selling content | `SellView` (More tab) |
| `/contact/` | `ContactView` (More tab, and linked from Home) |
| Footer legal | `DisclosuresView` + external links |
| — (app-native) | **Saved** tab, map search, filters, share |

The app adds native capability the website does not have — map search, on-device
saved properties, native share, tap-to-call. That is deliberate: see
`docs/APP_STORE_CHECKLIST.md` on guideline 4.2.

---

## Brand facts extracted

```
Company        Lanier Properties (trades as Lanier Realty)
Founded        2024
Address        114 S Main St, Middleton, TN 38052
Phone          731-203-8415
Email          info@lanierproperties.net
Agents         7 (3 named: Karen Lanier, Lane Lanier, Christi McCaslin)
Region         West Tennessee and North Mississippi
Counties       Hardeman, McNairy, Hardin, Tippah, Alcorn, Fayette
Values         Honesty, hard work, hometown values
MLS            Memphis area — appears as "MemphisTN" in listing URLs
```

Christi McCaslin's direct line (731-518-5261) and email are published on her own
public profile and are included in `AgentDirectory`.

---

## Copy carried into the app verbatim

From the About page:

> Lanier Realty has guided West Tennessee and North Mississippi families home
> since 2024 — with local insight, honest guidance, and care that extends well
> beyond closing day.

> Our vision is to become the most trusted and preferred real estate partner in
> Hardeman, McNairy, Hardin, Tippah, Alcorn, and Fayette counties.

From the Buy page (reproduced in `BuyView`'s FAQ):

> From first consultation to closing, most buyers are in their new home within
> 30–90 days… once an offer is accepted, closing typically takes 30–45 days.

> Conventional loans typically require 3–20% down; FHA loans can be as low as
> 3.5% with qualifying credit; VA and USDA loans may require no down payment.

Copy on the Sell screen and some supporting sentences were **written for the app**
in the brokerage's voice, because the corresponding website text was not indexed.
Review those before release — they are all in `BuySellViews.swift` and
`BrandInfo.swift`.
