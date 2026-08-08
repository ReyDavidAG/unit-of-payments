# DESIGN.md

Locked design system for `unit_of_payments`. Every screen, view and widget reads from these tokens.
Code rules are in [CLAUDE.md](CLAUDE.md); this file governs how it looks.

```
Hallmark · genre: modern-minimal · theme: Coral · scope: system (mobile app)
pre-emit critique: P5 H4 E5 S5 R5 V4
```

**Scope note.** Hallmark's macrostructure, nav and footer archetypes are page constructs for the web.
This is a mobile app, so those picks are skipped on purpose. What carries over is everything that
actually decides whether the UI looks made or generated: the token system, the type discipline, the
motion budget and the anti-pattern list.

---

## 1. Context

| | |
|---|---|
| **Audience** | One person tracking their own subscriptions. Opens the app for ten seconds, wants one number |
| **Use case** | Answer "what am I paying, and what hits next" — everything else is secondary |
| **Tone** | Utilitarian, warm. Calm about money. Not a bank, not a toy |
| **Genre** | modern-minimal — restraint with conviction |
| **Theme** | Coral — warm-grey paper, one coral accent, Geist throughout |

These were inferred, not asked. If the tone is wrong, say so and the palette moves with it.

---

## 2. Colour

OKLCH is the source of truth; the hex is the derived sRGB the Flutter code ships. Anchor hue **40**
(warm), accent hue **32** (coral). Every neutral carries a trace of the anchor — a warm accent over
cool greys is the mismatch nobody can name but everybody sees.

### Light

| Token | OKLCH | Hex | Use |
|---|---|---|---|
| `paper` | `oklch(97% 0.008 40)` | `#FAF3F1` | Screen background |
| `surface` | `oklch(94.5% 0.010 40)` | `#F3EBE8` | Cards, sheets |
| `surface2` | `oklch(91% 0.012 40)` | `#E9DFDB` | Pressed / hovered surface |
| `rule` | `oklch(87% 0.011 40)` | `#DBD2CF` | Decorative dividers only |
| `neutral` | `oklch(58% 0.012 40)` | `#817875` | Control borders, icons, large text |
| `muted` | `oklch(44% 0.013 40)` | `#59504D` | Secondary text |
| `ink` | `oklch(20% 0.014 40)` | `#1C1411` | Primary text, filled buttons |
| `accent` | `oklch(62% 0.17 32)` | `#D9553F` | Marks and fills — never small text |
| `accentInk` | `oklch(37% 0.12 32)` | `#721E10` | Accent-coloured **text** |
| `focus` | `oklch(55% 0.19 32)` | `#C8331A` | Focus ring |
| `danger` | `oklch(52% 0.19 18)` | `#BD1F3D` | Destructive actions only |

### Dark

Its own palette, not an inverted light one. Taken from Hallmark's Wayfare
example (`Manifesto-dark`): warm anchor at hue 60, ink drifting to 80, and a
bleed-red accent at 25 in place of the light theme's coral.

| Token | OKLCH | Hex |
|---|---|---|
| `paper` | `oklch(13% 0.010 60)` | `#0A0704` |
| `surface` | `oklch(18% 0.012 60)` | `#16100C` |
| `surface2` | `oklch(24% 0.014 60)` | `#241E19` |
| `rule` | `oklch(28% 0.012 60)` | `#2D2823` |
| `neutral` | `oklch(62% 0.014 70)` | `#8C857D` |
| `muted` | `oklch(80% 0.012 80)` | `#C2BDB5` |
| `ink` | `oklch(96% 0.010 80)` | `#F5F1EA` |
| `accent` | `oklch(66% 0.225 25)` | `#FE4145` |
| `accentInk` | `oklch(80% 0.110 25)` | `#FDA19A` |
| `focus` | `oklch(78% 0.165 70)` | `#F9A216` |
| `danger` | `oklch(62% 0.255 350)` | `#EA0C9B` |

Chroma is clamped to what sRGB can hold. The source is CSS `oklch`, which a
browser gamut-maps on the fly; Flutter ships literal ARGB, so the values here
are the highest in-gamut chroma at each lightness rather than the source
numbers.

**Danger is magenta in dark mode, red in light.** The dark accent *is* red, and
a destructive action in a second red is one nobody can tell apart from an
attention marker. Measured separation against the accent: ΔE 15.2 normal,
14.2 deuteran.

Elevation still goes lighter, never darker.

### Measured contrast

Computed, not estimated. WCAG 2.1 ratios against `paper`:

| Pair | Light | Dark | Floor |
|---|---|---|---|
| `ink` on paper | 16.55 | 16.45 | 4.5 |
| `muted` on paper | 7.15 | 9.15 | 4.5 |
| `neutral` on paper | 3.93 | 5.40 | 3.0 (large text / borders **only**) |
| `accentInk` on paper | 10.04 | 12.58 | 4.5 |
| `focus` on paper | 4.86 | 8.05 | 3.0 |
| `paper` on `ink` fill | 16.55 | 16.45 | 4.5 |

`neutral` is below 4.5 in light mode. It is **not** a body-text colour there — it is for borders,
icons and text ≥ 24 px. Secondary copy uses `muted`.

### Accent discipline

The accent is a highlighter, not a colour block. It occupies **≤ 3% of any screen**. It is allowed on:
the focus ring, the active tab or nav item, the "due now" marker, a small square anchoring a heading,
and the FAB. It is **not** allowed as a full-width button fill, a header band, or a section background.

**The primary button is `ink`-filled, not accent-filled.** That is the canonical modern-minimal pair —
ink fill for primary, outlined for secondary — and it is also the only version that clears 4.5:1 on the
label. Coral on paper measures 3.60, which is fine for a boundary and wrong for text.

### Card swatches

`cards.color` is user data, and user-chosen colours are the single fastest way to destroy a palette.
The picker offers **only these six** and nothing else — no free picker, no hex field.

| Name | Hex | OKLCH |
|---|---|---|
| Ámbar | `#D57700` | `oklch(66% 0.155 60)` |
| Verde | `#227405` | `oklch(49% 0.155 140)` |
| Cian | `#0CA3BE` | `oklch(66% 0.115 215)` |
| Índigo | `#494ECF` | `oklch(50% 0.195 275)` |
| Rosa | `#DC58B7` | `oklch(66% 0.195 340)` |
| Olivo | `#686800` | `oklch(50% 0.11 110)` |

**Six, not eight, and the lightness alternates.** An earlier set used eight hues at a constant
`L 62`. It failed the categorical colour checks outright: amber against olive measured ΔE 1.1 under
deuteranopia — the same colour to a red-green colourblind reader — and teal against cyan measured
ΔE 7.4 under *normal* vision. Constant lightness with only hue varying is exactly what produces
that. Alternating lightness carries the separation that hue alone cannot.

Verified with a validator, not by eye: both papers pass the lightness band, the chroma floor,
adjacent-pair CVD separation (worst 8.8 protan) and the normal-vision floor (worst 23.3). One set
serves both modes.

Three swatches fall below 3:1 against the card surface, which obligates relief: **a swatch never
appears without its alias in text beside it**, and the proportion bar is always paired with the
per-card list that names and totals each segment. Colour is never the only carrier of identity.

Hues 20–45 are reserved — a card swatch in coral would read as an interactive accent mark.

## 3. Typography

Two families: **Geist** and **Geist Mono**. Bundled as assets under `lib/assets/fonts/`, OFL licensed,
no runtime fetch and no font package — the app works offline, which is the point of the whole thing.

- **Geist 400** — body and everything unlabelled
- **Geist 500** — buttons, tabs, form labels
- **Geist 700** — every heading. Body 400 against heading 700 is a 300-unit gap; 600 would read as a
  default setting rather than a decision
- **Geist Mono 400/500** — **one role only: monetary figures and card last4.** Every amount in the app
  is mono with tabular figures, so columns of money align down the screen. Nothing else gets mono

### Scale

Major third (1.25) from a 16 px base, in logical pixels:

| Token | Size | Weight | Line height | Use |
|---|---|---|---|---|
| `display` | 40 | 700 | 1.08 | The one number on the dashboard |
| `xl` | 31 | 700 | 1.15 | Screen title |
| `lg` | 25 | 700 | 1.2 | Section heading |
| `md` | 20 | 700 | 1.3 | Card title |
| `base` | 16 | 400 | 1.5 | Body — the floor for reading copy |
| `sm` | 13 | 400/500 | 1.4 | Labels, metadata, helper text |
| `xs` | 11 | 500 | 1.3 | Tracked uppercase micro-label. `letter-spacing: 0.10em` |

**No more than five of these on one screen.** More hierarchy comes from weight and colour, not another
size. Tracking is `-0.02em` on `display`/`xl`, `-0.01em` on `lg`/`md`, `0` on body.

Money is **always** `tabularFigures`. A subscription list where the decimal points don't line up looks
broken even to someone who can't say why.

---

## 4. Space and shape

4 pt scale, named by role. Never type a raw number in a widget.

`3xs 2 · 2xs 4 · xs 8 · sm 12 · md 16 · lg 24 · xl 40 · 2xl 64 · 3xl 96`

Radii: **8** inputs and chips · **12** cards and sheets · **999** pills, FAB and avatars.

**Rhythm must be uneven.** If the card padding equals the list gap equals the screen padding, the
screen is a template. Screen padding `md`, card padding `lg`, gap between cards `sm`, gap between
sections `xl`. Generous above a section heading, tight below it.

**Depth is weight and scale, not shadow.** One shadow exists in the system — `0 1px 2px ink/5%` on the
FAB and bottom sheet. Cards are separated by their `surface` fill against `paper`, not by a drop
shadow. No card inside a card, ever: pick the outer or the inner, not both.

---

## 5. Motion

Three durations, three curves, and a hard budget of **two moving things per screen**.

| Token | Value | Use |
|---|---|---|
| `micro` | 120 ms | Press feedback, toggle, colour shift |
| `short` | 220 ms | Sheet handle, chip selection, tooltip |
| `long` | 420 ms | Route transition, bottom sheet, expand |

| Curve | Cubic | Use |
|---|---|---|
| `easeOut` | `(0.16, 1, 0.3, 1)` | Anything entering |
| `easeIn` | `(0.7, 0, 0.84, 0)` | Anything leaving — at 75% of the enter duration |
| `easeInOut` | `(0.65, 0, 0.35, 1)` | State toggles |

Animate opacity and transform only. Never a bounce, never an overshoot, never an infinite loop that
isn't a real loading indicator. Honour `MediaQuery.disableAnimations` — spatial motion collapses to a
150 ms fade.

If you can't say what a transition communicates, delete it. Most screens here need none.

---

## 6. Component voice

- **Subscription row** — name in `base` 400, next charge date in `sm` `muted`, amount right-aligned in
  Geist Mono with tabular figures. The card colour appears as a 3 px left bar, never as a filled tile.
- **Card total** — alias in `md` 700, monthly total in `display` mono. The swatch is a small square
  beside the alias, not a background.
- **Primary button** — `ink` fill, `paper` label, Geist 500, pill radius, full width on forms only.
- **Secondary button** — `neutral` 1 px outline, `ink` label, transparent fill.
- **Destructive** — `danger` text on transparent, never a filled red button. Confirm with an undo
  snackbar, not a modal.
- **Empty state** — one sentence in `base` `muted` and one button. No illustration, no icon balloon.
- **Focus** — a 2 px `focus` ring, always visible, **never animated in**. It appears instantly.

Every interactive widget ships all its states: default, pressed, focused, disabled, loading, error.

### Copy

**All user-facing text is Spanish (es-MX, tuteo).** The app locale is fixed to `es-MX` so Material's
own strings follow. Code and comments stay English — see [CLAUDE.md](CLAUDE.md).

Verbs, not nouns. *"Agregar suscripción"*, not *"Gestión de suscripciones"*. Amounts always carry
their currency. Dates are relative when close (*"en 3 días"*) and absolute when not (*"12 sep"*). No
invented numbers anywhere — an empty dashboard shows an em dash and a label, never a fake total.

---

## 7. Banned in this project

Carried from the Hallmark anti-pattern list, plus the ones this domain invites:

- Pure `#000` or `#FFF` anywhere
- Zero-chroma greys — every neutral carries the anchor tint
- Gradients on text; three-stop gradients at all
- Glassmorphism, blurred translucent panels
- Emoji as iconography
- Everything centred — the primary axis of every screen is left
- Three identical cards in a row with icon-above-title-above-body
- A drop shadow doing a border's job
- Bounce or spring easing on any UI state
- Red-and-green as the only signal for a state — always pair with an icon or a label
- Invented figures, fake totals, placeholder testimonials
- Italic headings

---

## 8. Where the tokens live

| File | Holds |
|---|---|
| [lib/config/theme/app_colors.dart](lib/config/theme/app_colors.dart) | Both palettes and the card swatches |
| [lib/config/theme/app_typography.dart](lib/config/theme/app_typography.dart) | Families, scale, the money style |
| [lib/config/theme/app_spacing.dart](lib/config/theme/app_spacing.dart) | Spacing scale and radii |
| [lib/config/theme/app_motion.dart](lib/config/theme/app_motion.dart) | Durations and curves |
| [lib/config/theme/app_theme.dart](lib/config/theme/app_theme.dart) | Assembles `ThemeData` for both modes |

A widget that hardcodes a colour, a size, a radius or a duration is a bug. Reference the token.
