# DESIGN.md

Locked design system for **Vence** (package `unit_of_payments`). Every screen, view and widget reads
from these tokens. Code rules are in [CLAUDE.md](CLAUDE.md); this file governs how it looks.

```
Hallmark · genre: modern-minimal · scope: system (mobile app)
theme: Hum (light) + Manifesto-dark (dark) · anchor hue 70-82 warm
pre-emit critique: P5 H4 E4 S5 R3 V4
```

**This document records what is implemented, not what was once planned.** It was re-derived from
`lib/config/theme/` on 2026-08-08, and every contrast number below is computed from the shipping hex
values, not estimated. Section 10 lists where the implementation knowingly departs from the rules
above it.

**Scope note.** Hallmark's macrostructure, nav and footer archetypes are page constructs for the web
and are skipped on purpose. What carries over is what decides whether the UI looks made or generated:
the token system, the type discipline, the motion budget and the anti-pattern list.

---

## 1. Context

| | |
|---|---|
| **Audience** | One person tracking their own subscriptions. Opens the app for ten seconds, wants one number |
| **Use case** | Answer "what am I paying, and what hits next" — everything else is secondary |
| **Tone** | Utilitarian, warm. Calm about money. Not a bank, not a toy |
| **Genre** | modern-minimal — restraint with conviction |
| **Theme** | Warm cream paper, terracotta identity, Geist throughout |

These were inferred, not asked.

---

## 2. Colour

OKLCH is the source of truth; hex is the derived sRGB that Flutter ships. Both modes anchor warm —
light on hue **67–82**, dark on **55–82**. Every neutral carries a trace of the anchor: a warm accent
over cool greys is the mismatch nobody can name but everybody sees.

The two modes are **not** inversions of each other. Light is Hallmark's Hum palette — baked
bread-crust terracotta on cream. Dark is Wayfare's `Manifesto-dark` — near-black warm paper with a
bleed-red accent. They share a temperature, not a hue.

### Light

| Token | OKLCH | Hex | Use |
|---|---|---|---|
| `paper` | `oklch(96.8% 0.010 82)` | `#F8F4ED` | Screen background |
| `surface` | `oklch(94.2% 0.014 78)` | `#F1EBE2` | Cards, sheets, input fill |
| `surface2` | `oklch(90.3% 0.023 72)` | `#E9DDCF` | Pressed / splash / disabled fill |
| `rule` | `oklch(86.8% 0.025 77)` | `#DDD2C2` | Dividers, `outlineVariant` |
| `neutral` | `oklch(60.0% 0.023 67)` | `#8A7E72` | Control borders, icons, hints |
| `muted` | `oklch(49.9% 0.020 67)` | `#6B6157` | Secondary text |
| `ink` | `oklch(21.8% 0.000 90)` | `#1A1A1A` | Primary text, snackbar, tooltip |
| `accent` | `oklch(62.4% 0.111 60)` | `#B8763B` | `colorScheme.secondary` |
| `accentInk` | `oklch(39.9% 0.085 50)` | `#6B3818` | Accent-coloured **text** |
| `focus` | `oklch(62.4% 0.111 60)` | `#B8763B` | `focusColor` |
| `primary` | `oklch(62.4% 0.111 60)` | `#B8763B` | Buttons, FAB, focused input border |
| `danger` | `oklch(51.9% 0.190 18)` | `#BD1F3D` | Destructive actions only |

`accent`, `focus` and `primary` are the same terracotta on purpose — one chromatic identity, not three
competing ones. `ink` is the one deliberately achromatic token in the system: pure neutral so text
never tints.

### Dark

| Token | OKLCH | Hex | Use |
|---|---|---|---|
| `paper` | `oklch(13.1% 0.011 74)` | `#0A0704` | Screen background |
| `surface` | `oklch(17.9% 0.013 55)` | `#16100C` | Cards, sheets, input fill |
| `surface2` | `oklch(24.0% 0.013 62)` | `#241E19` | Pressed / splash / disabled fill |
| `rule` | `oklch(28.1% 0.012 67)` | `#2D2823` | Dividers |
| `neutral` | `oklch(62.0% 0.015 71)` | `#8C857D` | Control borders, icons, hints |
| `muted` | `oklch(80.0% 0.012 80)` | `#C2BDB5` | Secondary text |
| `ink` | `oklch(95.9% 0.010 82)` | `#F5F1EA` | Primary text |
| `accent` | `oklch(65.9% 0.224 25)` | `#FE4145` | `colorScheme.secondary` |
| `accentInk` | `oklch(79.9% 0.111 25)` | `#FDA19A` | Accent-coloured **text** |
| `focus` | `oklch(78.1% 0.165 70)` | `#F9A216` | `focusColor` |
| `primary` | `oklch(60.5% 0.084 234)` | `#4A8AAC` | Buttons, FAB, focused input border |
| `danger` | `oklch(62.0% 0.255 350)` | `#EA0C9B` | Destructive actions only |

Chroma is clamped to what sRGB can hold. The source is CSS `oklch`, which a browser gamut-maps on the
fly; Flutter ships literal ARGB, so these are the highest in-gamut chroma at each lightness rather
than the source numbers.

**`primary` is blue in dark and terracotta in light.** The dark accent is a bleed red; a terracotta
button beside it would read as a washed-out version of the same hue. Blue is the one direction that
separates cleanly from both the red accent and the amber focus.

**`danger` is magenta in dark and red in light,** for the same reason: the dark accent *is* red, and a
destructive action in a second red is one nobody can tell apart from an attention marker. Measured
separation against the accent: ΔE 15.2 normal, 14.2 deuteran.

Elevation goes lighter, never darker, in both modes.

### Semantic palette

Four hues that communicate state rather than identity. Each mode lifts them to sit on its own paper.

| Token | Light | Dark | Meaning |
|---|---|---|---|
| `success` | `#5DBA76` | `#7BC96F` | Settled, synced, on track |
| `info` | `#3D7FE8` | `#6BA0F5` | Neutral information |
| `warning` | `#E0A938` | `#F5C842` | Charge approaching |
| `critical` | `#F26B82` | `#F77890` | Overdue, alert |

These are **fills and markers, never text.** None of them clears 4.5:1 on light paper.

### Tab identity

The bottom nav gives each destination its own colour so the active tab is legible without reading the
label. A standard `NavigationBar` paints every selection the same primary; this one does not.

| Tab | Light | Dark |
|---|---|---|
| Resumen | `tabBlue` `#4A8AAC` | `tabBlue` `#4A8AAC` |
| Suscripciones | `success` | `successDark` |
| Tarjetas | `tabPurple` `#5B2C6F` | `tabPurpleDark` `#7B3D9E` |
| Avisos | `critical` | `criticalDark` |

Resumen holds the same blue in both modes — it is the home tab and should not shift identity when the
theme does. Tarjetas borrows the aubergine from the brand mark.

Colour is never the only carrier: every tab ships its label, its outlined/filled icon pair, and a
`Semantics(selected:)` flag.

### Card swatches

`cards.color` is user data, and free colour choice is the fastest way to destroy a palette. The picker
offers **only these eight** — no free picker, no hex field. Lightness alternates deliberately; a set at
constant lightness separates by hue alone, which is exactly what fails for a colourblind reader.

| Name | Hex | OKLCH | vs light `surface` | vs dark `surface` |
|---|---|---|---|---|
| Ámbar | `#D57700` | `oklch(66.0% 0.155 60)` | 2.74 | 5.81 |
| Olivo | `#686800` | `oklch(50.1% 0.109 110)` | 4.97 | 3.20 |
| Verde | `#227405` | `oklch(49.0% 0.155 140)` | 4.97 | 3.20 |
| Cian | `#0CA3BE` | `oklch(65.9% 0.115 215)` | 2.53 | 6.28 |
| Índigo | `#494ECF` | `oklch(50.0% 0.195 275)` | 5.41 | 2.94 |
| Rosa | `#DC58B7` | `oklch(66.1% 0.195 340)` | 2.89 | 5.50 |
| Morado | `#7B2D9E` | `oklch(46.3% 0.180 313)` | 6.54 | 2.43 |
| Amarillo | `#D9A52A` | `oklch(75.1% 0.143 84)` | 1.89 | 8.41 |

`#494ECF` (Índigo) is the default for a new card.

Several swatches fall below 3:1 against the card surface, which obligates relief: **a swatch never
appears without its alias in text beside it.** Colour is never the only carrier of identity. See
§10 for the open CVD finding on this set.

### Card brand marks

A brand reaches the UI **only as its bundled artwork**, never as a colour value.
[card_assets.dart](lib/data/models/cards/card_assets.dart) maps a brand to its WebP and nothing else;
there are no literal colours in the app outside `app_colors.dart`.

Brand colours are external identity, not palette. They were never ours to re-tune, which is exactly
why they could not be trusted on this paper: Visa navy measured **1.33:1** and Mastercard red
**2.14:1** on `surfaceDark`. Which of *your* cards a row belongs to is the swatch's job.

### Measured contrast

Computed, not estimated. WCAG 2.1 ratios against `paper`.

| Pair | Light | Dark | Floor |
|---|---|---|---|
| `ink` on paper | 15.87 | 17.85 | 4.5 |
| `muted` on paper | 5.52 | 10.76 | 4.5 |
| `neutral` on paper | 3.61 | 5.52 | 3.0 (borders / large text **only**) |
| `accentInk` on paper | 8.69 | 10.28 | 4.5 |
| `accent` on paper | 3.36 | 5.80 | 3.0 |
| `focus` on paper | 3.36 | 9.77 | 3.0 |
| `danger` on paper | 5.59 | 4.81 | 4.5 |
| `onPrimary` on `primary` fill | **3.36** | 5.28 | 4.5 |

`neutral` is below 4.5 in light mode. It is **not** a body-text colour there — borders, icons and text
≥ 24 px only. Secondary copy uses `muted`.

The primary button label in light mode measures 3.36 and does not clear the floor. This is a known
deviation, recorded in §10.

### Accent discipline

The accent family is a highlighter, not a colour block. Allowed on: the focus ring, the active tab
chip, the "due now" marker, the card swatch bar, and the FAB. **Not** allowed as a header band, a
section background, or a page-width fill.

The primary button is the one deliberate exception — it is terracotta-filled rather than ink-filled,
which buys chromatic identity at the cost of label contrast. See §10.

---

## 3. Typography

Two families: **Geist** and **Geist Mono**. Bundled under `lib/assets/fonts/`, OFL licensed, no
runtime fetch and no font package — the app works offline, which is the point of the whole thing.

- **Geist 400** — body and everything unlabelled
- **Geist 500** — buttons, tabs, form labels
- **Geist 700** — every heading. A 300-unit gap against the body reads as a decision; 600 reads as a
  default
- **Geist Mono 400/500** — **one role only: monetary figures and card last4.** Every amount is mono
  with tabular figures so columns of money align down the screen. Nothing else gets mono

### Scale

Major third (1.25) from a 16 px base, in logical pixels. The names below are the `TextTheme` slots the
code actually assigns.

| Slot | Size | Weight | Line height | Tracking | Use |
|---|---|---|---|---|---|
| `displayLarge` | 40 | 700 | 1.08 | −0.02em | Reserved display |
| `headlineLarge` | 31 | 700 | 1.15 | −0.02em | Screen title |
| `titleLarge` | 25 | 700 | 1.20 | −0.01em | AppBar title, section heading |
| `titleMedium` | 20 | 700 | 1.30 | −0.01em | Card title |
| `bodyLarge` | 16 | 400 | 1.50 | 0 | Body — the floor for reading copy |
| `bodySmall` | 13 | 400 | 1.40 | 0 | Metadata, helper text (`muted`) |
| `labelLarge` | 13 | 500 | 1.40 | 0 | Buttons, form labels |
| `labelSmall` | 11 | 500 | 1.30 | +0.10em | Tracked uppercase micro-label |

Three mono styles sit outside the `TextTheme`, because money is a role and not a heading level:

| Helper | Size | Weight | Use |
|---|---|---|---|
| `displayAmount` | 40 | 500 | The one number on the dashboard |
| `amount` | 16 | 400 | Every amount in a list |
| `figure` | 13 | 400 | Card last4 and short figure runs |

**No more than five sizes on one screen.** More hierarchy comes from weight and colour, not another
size. Money is **always** `tabularFigures` — a list where the decimal points don't line up looks broken
even to someone who can't say why.

---

## 4. Space and shape

4 pt scale, named by role. Never type a raw number in a widget.

`xs3 2 · xs2 4 · xs 8 · sm 12 · md 16 · lg 24 · xl 40 · xl2 64 · xl3 96`

Role aliases: `screenPadding md · cardPadding lg · listGap sm · sectionGap xl · swatchBar 3`

Radii: **8** (`radiusInput`) inputs, chips, nav chips · **12** (`radiusCard`) cards, sheets, buttons,
FAB, list tiles · **999** (`radiusPill`) the card swatch picker only.

**Buttons and the FAB use `radiusCard`, not a pill.** A pill button beside a 12-radius card is two
shape languages on one screen.

**Rhythm must be uneven.** If card padding equals list gap equals screen padding, the screen is a
template. Generous above a section heading, tight below it.

**Depth is weight and scale, not shadow.** The FAB carries `elevation: 1`; nothing else does. Cards are
separated by their `surface` fill against `paper`. No card inside a card, ever.

---

## 5. Motion

Three durations, three curves, and a hard budget of **two moving things per screen**.

| Token | Value | Use |
|---|---|---|
| `micro` | 120 ms | Press feedback, toggle, colour shift, tooltip wait |
| `short` | 220 ms | List item entry, chip selection, nav chip |
| `long` | 420 ms | Route transition, bottom sheet, hero entry |
| `reduced` | 150 ms | Reduced-motion replacement for any spatial transition |

| Curve | Cubic | Use |
|---|---|---|
| `easeOut` | `(0.16, 1, 0.3, 1)` | Anything entering |
| `easeIn` | `(0.7, 0, 0.84, 0)` | Anything leaving — `AppMotion.exit()` runs it at 75% |
| `easeInOut` | `(0.65, 0, 0.35, 1)` | State toggles |

Two shared widgets own every entry animation:
[AnimatedListItem](lib/ui/widgets/common/motion/animated_list_item.dart) (fade-up, 40 ms stagger
capped at the fifth item) and [AnimatedHero](lib/ui/widgets/common/motion/animated_hero.dart)
(fade-down). Both collapse to their child when `MediaQuery.disableAnimations` is set.

Animate opacity and transform only. Never a bounce, never an overshoot, never an infinite loop that
isn't a real loading indicator. If you can't say what a transition communicates, delete it.

---

## 6. Component voice

- **The swatch bar** — a card's colour is drawn at **exactly one width, `swatchBar` (6)**, on every
  surface that shows a card: the subscription row, the card row, the summary total, the statement, and
  as a dot of the same diameter in the upcoming list and inside a card chip. One widget owns it —
  [swatch_card_widget.dart](lib/ui/widgets/common/swatch_card_widget.dart) — so the width cannot drift
  again. It ran 3 px in two places, 6 in a third and a brand navy in a fourth, and the same card read
  as four different things.

  It is always the **card's own swatch**, never its brand colour. Brand navy and brand red are external
  identity, they are not in this palette, and on the dark paper they measured 1.33 and 2.14. Meta lines
  are plain `muted` for the same reason: colour identity is the bar's job, and the bar can never be
  unreadable. A charge with no card gets `rule`, not a colour.

  A hard edge against the card fill, never a filled tile — the swatches are saturated and a filled row
  would compete with the amount. Full height via `IntrinsicHeight`, so a row that wraps to two lines
  does not leave a gap.
- **Subscription row** — name in `bodyLarge`, next charge in `bodySmall` `muted`, amount right-aligned
  in Geist Mono, swatch bar on the edge.
- **Card row and card total** — the same bar, plus the swatch as a 2 px ring around the brand art
  ([card_brand_thumbnail.dart](lib/ui/widgets/cards/card_brand_thumbnail.dart)). The ring is what makes
  the colour legible at thumbnail scale: the WebP fills its frame, so without it the swatch would only
  exist on the far edge. Brand and swatch answer two different questions — which network processes it,
  and which of *your* cards this is. Resumen is a view of the cards on Tarjetas, so it identifies them
  identically rather than inventing a second language.
- **Charge status** — three states, one column. **Active** is the default voice. **Paused** keeps the
  row on the list and drops everything that claims attention: the bar goes to `rule`, the name and
  amount to `onSurfaceVariant`, and `En pausa` replaces the countdown — an amber *"en 4 días"* on a
  stopped charge is a lie. **Cancelled** leaves the list entirely. Pausing offers an undo snackbar;
  cancelling asks in a dialog first, because there is no row left to undo from.
- **Warning badge** — an amber disc with an ink `!` and an ink hairline ring, on the row *and* on the
  tab. The ring is not decoration: the amber measures **1.79:1** on the light paper and has no
  silhouette without it. The glyph is not decoration either — colour alone cannot carry a warning.
  Used for exactly one thing today: a charge left on an archived card.
- **Installment form** — the user is asked for the **price and the term**, because that is how the
  promotion is sold and how they remember it. The monthly charge is computed and shown back
  (`12 pagos de $833.33`), never typed. The term is a set of chips with an `Otro` escape, matching how
  the custom billing cycle already works — nobody should type `12` into a field for the one number
  that only ever takes a handful of values.
- **Contado** — the first chip in the term row, with its own glyph, because it is the one option there
  that does *not* spread the charge over months. `1 MSI` is not a phrase anybody says. Underneath it is
  an installment plan of length one, so it reuses the same trigger, the same progress maths and the
  same constraint; the row reads `Contado`, never `MSI 1 de 1`, and the amount field drops the word
  *total* since nothing is being split.
- **Term chips** — `info` at 15% with an `info` outline and an `onSurface` label. A solid `info` fill
  left the label at **3.55:1** in light mode and no token in the system cleared 4.5 on top of it. The
  15% wash is the grammar chips and segments already speak; `info` instead of `primary` is what keeps
  the MSI lane distinct.
- **Installment row** — the same subscription row, with the cycle position replaced by progress:
  `MSI 3 de 12 · BBVA`. *"Mensual"* is true of an installment plan and useless on it. The peso figure
  still owed is **not** here — it belongs to the card total and the statement, where it can be summed.
- **Statement card** — alias and deadline on the left, statement total right in mono. The deadline
  carries the semantic tint by proximity, same scale as a charge. When the card has no due day it
  says so and names the missing field instead of showing a date it cannot know.
- **Reimbursement** — a charge someone else repays appends `Juan te paga` to the meta line, and the
  statement shows what is left after reimbursements. Never a badge, never a second colour.
- **Primary button** — `primary` fill, `paper` label, Geist 500, `radiusCard`, full width on forms only.
- **Secondary button** — `primary` 1 px outline, `primary` label, transparent fill.
- **Destructive** — `danger` text on transparent, never a filled red button. Confirm with an undo
  snackbar where the action is reversible, a dialog only where it is not — or where the consequence
  is invisible from where the button is. Archiving a card is reversible and still asks, because the
  charges it strands are on another screen.
- **Confirm dialog** — one widget owns every "are you sure":
  [confirm_dialog.dart](lib/ui/widgets/common/confirm_dialog.dart). Dismissing counts as no. The
  confirm button stays in the default primary voice unless the action is destructive; an app where
  every dialog is red teaches the user to ignore red. On destructive dialogs the label is paired per
  mode — the light cream measures **3.81:1** on `dangerDark` and cannot be used in both.
- **Empty state** — one sentence in `bodyLarge` `muted` and one button. No illustration, no icon balloon.
- **Error state** — the same shape, with the button reading `Reintentar`. It scrolls, so pull-to-refresh
  keeps working while it is on screen, and it never shows a code, a stack trace or a raw driver
  message. One widget owns this: [error_retry_widget.dart](lib/ui/widgets/common/error_retry_widget.dart).
- **Skeleton** — shimmer over `surface2`/`surface` (light) or `surface`/`surface2` (dark), shaped like
  the content it replaces. Never a spinner where a skeleton fits.
- **Segmented control** — a hairline `rule` outline at `radiusInput`, the selected segment washed in
  `primary` at 15% with an `ink` label, the rest transparent with a `muted` one. Same selection wash as
  a chip, so a form that carries both does not speak two languages. **Never the raw accent as a fill** —
  that is what Material does when the control is left unthemed, and it is a banned block of colour.
  48 px tall, because a segment is a tap target before it is a label.
- **Focus** — a 2 px `primary` ring, always visible, **never animated in**.

Every interactive widget ships all its states: default, pressed, focused, disabled, loading, error.

### Copy

**All user-facing text is Spanish (es-MX, tuteo).** The app locale is fixed to `es-MX` so Material's
own strings follow. Code and comments stay English — see [CLAUDE.md](CLAUDE.md).

Verbs, not nouns. *"Agregar suscripción"*, not *"Gestión de suscripciones"*. Amounts always carry their
currency, taken from the profile. Dates are relative when close (*"En 3 días"*, *"Mañana"*) and
absolute when not (*"12 sep"*). No invented numbers anywhere — an empty dashboard shows an em dash and
a label, never a fake total.

---

## 7. Theme control

Three modes, persisted locally: **Sistema · Claro · Oscuro**
([theme_mode_enum.dart](lib/config/theme/theme_mode_enum.dart)).

Storage is `shared_preferences`, not the `profiles` row and not the keychain. The theme must apply on
the sign-in screen, where there is no session to read a row from, and must work with no network. It is
a preference, not a secret.

Two entry points: a `SegmentedButton` with all three modes in Perfil, and a two-state
[ThemeToggleButton](lib/ui/widgets/common/theme_toggle_button.dart) in every tab AppBar and on the auth
screens, which flips straight to the explicit opposite of the current mode.

The mode is applied to `state` before the disk write, so the theme changes on the frame of the tap.

---

## 8. Banned in this project

- Pure `#000` or `#FFF` anywhere
- Zero-chroma greys — every neutral carries the anchor tint (`ink` is the one deliberate exception)
- Gradients on text; three-stop gradients at all
- Glassmorphism, blurred translucent panels
- Emoji as iconography
- Everything centred — the primary axis of every screen is left
- Three identical cards in a row with icon-above-title-above-body
- A drop shadow doing a border's job
- Bounce or spring easing on any UI state
- Colour as the only signal for a state — always pair with an icon or a label
- Invented figures, fake totals, placeholder testimonials
- Italic headings

---

## 9. Where the tokens live

| File | Holds |
|---|---|
| [app_colors.dart](lib/config/theme/app_colors.dart) | Both palettes, semantics, tabs, card swatches |
| [app_typography.dart](lib/config/theme/app_typography.dart) | Families, scale, the money styles |
| [app_spacing.dart](lib/config/theme/app_spacing.dart) | Spacing scale, role aliases, radii |
| [app_motion.dart](lib/config/theme/app_motion.dart) | Durations and curves |
| [app_theme.dart](lib/config/theme/app_theme.dart) | Assembles `ThemeData` for both modes |
| [theme_mode_enum.dart](lib/config/theme/theme_mode_enum.dart) | The three user-facing modes |

A widget that hardcodes a colour, a size, a radius or a duration is a bug. Reference the token.

---

## 10. Known deviations

Measured, open, and deliberately not fixed in the change that produced this document. Each one is a
decision waiting to be made, not an oversight.

1. **Primary button label measures 3.36:1 in light mode** (`paper` on terracotta), against a 4.5 floor.
   The chromatic button was chosen over an ink fill for identity. Clearing the floor means either
   darkening `primary` toward `accentInk` or reverting the fill to `ink`.
2. **Nav chip icons fall below the 3:1 non-text floor.** Paper icon on chip: Suscripciones 2.19 light /
   1.84 dark, Avisos 2.66 / 2.38, Resumen 3.47 / 3.47, Tarjetas 9.41 / 6.38. The label under each chip
   carries the meaning, so nothing is unreachable — but the icon itself is decorative at those ratios.
3. **Input hints measure 3.34:1** (`neutral` on `surface`, light). Hint text is not required to clear
   4.5 by WCAG, but at this ratio it is close to invisible in sunlight.
4. **The accent budget is exceeded.** The ≤3%-of-screen rule predates the terracotta button fill and
   the four coloured nav chips. Chromatic identity won; the rule as written no longer describes the app.
5. **Card swatches fail all-pairs CVD separation.** Adjacent-pair checking passes, but
   [SpendSplitWidget](lib/ui/widgets/dashboard/spend_split_widget.dart) sorts segments by amount, so any
   two swatches can end up touching. Worst pairs: Olivo↔Verde ΔE 1.5 deutan / 8.3 normal, Rosa↔Cian
   ΔE 2.6 deutan. Eight distinct lightness steps do not fit the usable band; the fix is to drop the
   proportion bar rather than shrink the palette further.
6. **`AppMotion.reduced` is defined and never read.** Reduced motion is honoured by collapsing to the
   child, not by shortening the duration, so the token has no consumer.
7. **`colorScheme.secondary` is never consumed.** `accent` and `accentInk` reach the UI only through
   the snackbar action colour; the terracotta identity travels as `primary` instead.
8. **The per-letter identity palette is outside this system and fails contrast in both modes.**
   [letter_palette.dart](lib/config/theme/letter_palette.dart) fixes 26 saturated colours while the
   surface under them flips between `#F1EBE2` and `#16100C`. Measured against both: **26 of 26 fail
   4.5:1 in at least one mode**, six (`E H Q R S T`) fail in both, and nine light / eight dark fall
   under the 3:1 floor the avatar's border needs. A fixed palette cannot sit on two grounds — it needs
   a per-mode variant, or a fixed lightness with only the hue varying.
9. **The profile action buttons are the least legible controls in the app.** *"Cerrar sesión"* is
   cream on `critical`: **2.66:1** light, **2.38:1** dark, because `AppColors.paper` is hardcoded for
   both modes. *"Cambiar contraseña"* is `warning` on paper at **1.93:1** in light.
   [account_actions.dart](lib/ui/widgets/profile/account_actions.dart) needs the same per-mode pairing
   [confirm_dialog.dart](lib/ui/widgets/common/confirm_dialog.dart) uses.
10. **Eleven widgets hardcode the type instead of reading the token.**
    `fontFamily: 'Geist', fontSize: 13, fontWeight: w500` is `labelLarge` character for character, and
    `fontSize: 15 / 32 / 48` are off the scale entirely — it runs 40 / 31 / 25 / 20 / 16 / 13 / 11.
    `flutter analyze` cannot see any of it.
