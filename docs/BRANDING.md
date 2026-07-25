# Matching the website's branding exactly

The site could not be reached from the build environment (see `SITE_AUDIT.md`),
so the app ships with a **placeholder palette and stand-in fonts**. Everything
visual is centralised, so making the app match the website exactly is a short,
mechanical job — no view files need editing.

There are exactly three places to touch:

| What | Where |
|---|---|
| Colours | `LanierProperties/Support/Assets.xcassets/Colors/*.colorset` |
| Fonts | `LanierProperties/Brand/Brand.swift` + `Support/Info.plist` |
| Images, logo, icon | `LanierProperties/Support/Assets.xcassets/*.imageset` |

Copy, phone numbers and legal text live in `Brand/BrandInfo.swift`.

---

## 1. Colours

Open lanierproperties.net in Chrome or Safari, right-click → Inspect, and read
the computed values off the header, buttons and body text.

```bash
# Or pull the whole palette from the stylesheet in one go:
curl -s https://lanierproperties.net/ \
  | grep -oE 'href="[^"]+\.css[^"]*"' | cut -d'"' -f2 | head -5
# then, for each stylesheet:
curl -s <stylesheet-url> | grep -oE '#[0-9a-fA-F]{6}' | sort | uniq -c | sort -rn | head -20
```

Map what you find onto these roles and edit the matching `.colorset`:

| Colorset | Role | Placeholder (light / dark) |
|---|---|---|
| `BrandPrimary` | Header, buttons, links | `#1F4739` / `#4E8F76` |
| `BrandPrimaryDark` | Pressed states | `#143026` / `#2F5C49` |
| `BrandAccent` | Highlights, saved heart | `#B8863B` / `#D6A659` |
| `BrandBackground` | Page background | `#FAF8F5` / `#121412` |
| `BrandSurface` | Cards | `#FFFFFF` / `#1C1F1D` |
| `BrandTextPrimary` | Headings, body | `#1A1D1B` / `#F2F0EC` |
| `BrandTextSecondary` | Captions | `#5C625E` / `#A9B0AB` |
| `BrandDivider` | Rules, field borders | `#E2DDD5` / `#2C302E` |
| `StatusActive/Pending/Sold` | Listing badges | greens / gold / grey |

Each colorset already has both a light and a dark variant. **Set both.** If the
website has no dark theme, keep the light hue for `BrandPrimary` and darken the
backgrounds — an app that ignores dark mode looks broken on iOS, and Apple's
reviewers do check.

Keep body text at **4.5:1** contrast against its background and large text at
**3:1**. A dark-green-on-cream palette passes comfortably; a gold-on-white one
usually does not.

---

## 2. Fonts

Find the families in DevTools (Computed → `font-family`) on a heading and a
paragraph.

```bash
curl -s https://lanierproperties.net/ | grep -oE "fonts.googleapis.com[^\"']*"
```

Then:

1. Get the `.ttf`/`.otf` files. Google Fonts are free to bundle. **A licensed
   font (Adobe Fonts, Monotype, Hoefler) usually may not be embedded in an app** —
   check the licence before shipping, and buy an app licence if needed.
2. Drop them in `LanierProperties/Support/Fonts/`.
3. List the filenames under `UIAppFonts` in `Support/Info.plist`.
4. Update the three family names at the top of `Brand.Font` in `Brand.swift`.

The **PostScript name** goes in `Brand.swift`, not the filename. To find it:

```bash
# macOS
fc-scan --format "%{postscriptname}\n" Inter-Regular.ttf
```

If the names don't match, nothing breaks: `Brand.Font.customFontsAvailable`
returns `false` and the whole app falls back to the system font. That fallback is
also why the project builds today with no font files at all.

Every text style is declared with `relativeTo:`, so Dynamic Type keeps working
after you swap the families — don't replace them with fixed-size `.custom(_:size:)`.

---

## 3. Images and the app icon

Save the website's assets and drop them into the matching imageset at `@2x` and
`@3x`:

| Imageset | Used by |
|---|---|
| `hero-home` | Home hero |
| `about-office` | About header |
| `LaunchLogo` | Launch screen |
| `agent-karen-lanier`, `agent-lane-lanier`, `agent-christi-mccaslin` | Team |

Missing images degrade gracefully — the hero keeps its gradient and text, agents
fall back to initials — so partial artwork is fine while you gather the rest.

### App icon

`AppIcon.appiconset` currently has an **empty slot**; the project builds but will
not pass App Store validation until you add artwork.

Requirements: **1024×1024 PNG, no alpha channel, no transparency, no rounded
corners** (iOS masks it), and no text that becomes illegible at 60pt.

```bash
# Flatten any transparency — the single most common upload rejection
sips -s format png --setProperty hasAlpha false logo-1024.png \
  --out LanierProperties/Support/Assets.xcassets/AppIcon.appiconset/AppIcon.png
```

Then add `"filename": "AppIcon.png"` to that imageset's `Contents.json`, or just
drag the file onto the slot in Xcode.

---

## 4. Copy and contact details

`Brand/BrandInfo.swift` holds the company name, phone, email, address, service
counties, marketing copy and legal text. Values I could not verify are marked
`// VERIFY`:

- `officeLatitude` / `officeLongitude` — refine to the exact rooftop pin
- `privacyPolicyURL` / `termsURL` — these URLs are guessed; **App Store Connect
  requires a working privacy-policy URL**, so confirm it resolves
- `socialLinks` — fill in from the website footer; entries with a `nil` URL are
  hidden automatically

`AgentDirectory` in `Models/Agent.swift` has three of the seven agents. Add the
rest — the Team screen adapts to any number of entries.
