# Theming cheat sheet

How theme selections become pixels (`TypeTypeIOS/DesignSystem/Theme/DemoTheme.swift`).

## One resolver, one palette

Everything colours through `DemoTheme.dynamicColor(role:)`. A `SurfaceRole`
has six cases (background, groupedBackground, pageBackground, surface,
groupedSurface, elevatedSurface) and the resolver gives each role its slot
from the active theme's surface set:

- **TypeType/Dynamic (classic):** system surfaces — page
  `systemGroupedBackground`, cards `secondarySystemGroupedBackground`.
- **Nord/Cream/Forest/Plum:** `themeSurfaceColors(isDark:)` — one surface set
  per theme per light/dark mode, copied 1:1 from Android's
  `AppearanceColorSchemes.kt` (the hex values are in comments next to the
  decimals; verify by round-tripping decimals → hex).
- **Manga personality:** `mangaScheme` rules — paper surfaces for the classic
  themes, theme surfaces for palette themes; Night paper reads dark even in
  light mode; text is `ink` (#171717 / #F5F3EA).
- **AMOLED** (dark only): all surfaces resolve to black.

`DemoThemePalette` is one value carrying every role (surfaces, separator,
text, accent, renderToken), injected at the root as
`EnvironmentValues.demoTheme`. The `DemoTheme.*` statics delegate to the same
resolver, so the environment palette and the statics can never disagree.

Text roles follow Android exactly: `onSurface` = Zinc950/Zinc100 (NOT tinted
per theme), `onSurfaceVariant` = Zinc700/Zinc400.

## Repaint without a refresh

- `liveThemeRepaint()` — wraps a subtree, reads `@Environment(\.demoTheme)`,
  keys identity on `palette.renderToken`. A theme change re-runs the modifier
  body and re-invokes the content closures, which re-read the statics. This
  is why theme switches apply instantly; never go back to
  `.id(DemoTheme.renderToken)` (only re-evaluated when some body re-ran).
- `DemoTheme.update` assigns `systemColorScheme` (environment scheme, so
  system light/dark flips react) and includes the resolved dark flag in the
  token signature.

## Settings pages: flat rows, no cards

The Android settings screens have no cards (`InfoCard`/`AccountSettingsCards`
are plain `Column`s; rows + `HorizontalDivider` on `background`). Therefore:

- Rows and UIKit cells are painted in the **page** colour (`background` role),
  so they sit flat on the page.
  Painting them with `surface` turns every section into a "rounded pile" —
  a regression the user rejects by name.
- Container recipe: `List` + `.listStyle(.plain)` +
  `.scrollContentBackground(.hidden)` + `.liveThemedList()` +
  `.liveThemeRepaint()`. Never `.insetGrouped`: the grouped style draws
  white rounded section cards on iOS 26/27 (the "rounded pills") that row
  backgrounds cannot cover — only the list style removes them.
- `liveSectionHeader()` = small uppercase caption (kerning 1.5, secondary) +
  `liveSectionSlotChrome()`: iOS 27 renders a system background into
  header/footer slots that UIKit appearance proxies cannot remove; the page
  colour bleeds past the slot insets (−24/−12, measured) to cover it. Every
  `footer:` body gets `.liveSectionSlotChrome()` too.

## Pitfalls

- Never map two surface roles to the same colour — invisible cards result.
- UIKit appearance proxies cache per trait; resolve colours immediately.
- Copy palette rules from Android source, not from screenshots.
- `SurfaceRole` has six cases — a role switch missing one fails to compile.
