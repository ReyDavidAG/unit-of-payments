# CLAUDE.md

Rules for working in this repository. **Follow them strictly.** If a rule blocks the task,
say so and stop — do not improvise around it.

Two companion documents, equally binding: [DESIGN.md](DESIGN.md) for how it looks and
[PLAN.md](PLAN.md) for what gets built and in what order.

## Project

`unit_of_payments` — Flutter app that notifies you of upcoming payments and shows all your
subscriptions in one place. Platforms: **iOS and Android only**. Org: `com.davidag`.

Work is done **feature by feature**, one branch per feature (`feature/<name>`).
**The user makes all commits.** Never commit or push unless explicitly asked.

## Commands

```bash
flutter pub get                              # install dependencies
flutter run --dart-define-from-file=.env     # run on a device/emulator
./scripts/format.sh                          # dart format + flutter analyze  <-- run at the end of EVERY change
```

Secrets are compile-time, never a bundled asset: copy `.env.example` to `.env` and pass
`--dart-define-from-file=.env` on every `run` and `build`. Read them only through
[Environment](lib/core/constants/environment.dart), never `String.fromEnvironment` directly.

`./scripts/format.sh` is the equivalent of Prettier here. It must exit clean (0 issues)
before any work is reported as done. No exceptions.

## Directory structure

```
lib/
  main.dart
  config/
    router/          # app_router.dart — routes and guards
    theme/           # app_theme.dart, app_colors.dart
  core/
    constants/       # environment, api constants, magic values
    helpers/         # feature logic that is not networking (date_helper.dart, ...)
    utils/           # small generic utilities
  data/
    models/<feature>/    # data classes + fromJson/toJson
    services/<feature>/  # I/O: db, http, storage, notifications
    providers/<feature>/ # state exposed to the UI
  ui/
    screens/<feature>/   # full routed pages
    views/<feature>/     # composable sub-views embedded in a screen
    widgets/<feature>/   # reusable widgets, grouped by feature
    widgets/common/      # widgets shared across features
  assets/
    images/ icons/
```

Group by **feature**, not by type, inside each layer. A new feature `subscriptions` creates
`data/models/subscriptions/`, `ui/screens/subscriptions/`, etc. — only the folders it needs.

## The three UI levels

Always split UI across these three levels. Never build a screen as one big file.

| Level | Lives in | Responsibility |
|---|---|---|
| **screen** | `ui/screens/` | A routed page. Owns the route, the `Scaffold`, and wiring to providers. Composes views/widgets — holds almost no layout of its own. |
| **view** | `ui/views/` | A meaningful section of a screen (a tab, a form step, a body). Composes widgets. |
| **widget** | `ui/widgets/` | A single reusable piece of UI. Knows nothing about routing. Receives data via constructor. |

Rule of thumb: if a piece of UI is used twice, or is more than ~60 lines inside a parent,
it moves down a level into its own file.

## File naming

All `snake_case`, always suffixed by its kind:

```
subscriptions_screen.dart      class SubscriptionsScreen
subscription_form_view.dart    class SubscriptionFormView
subscription_card_widget.dart  class SubscriptionCardWidget
subscription_model.dart        class SubscriptionModel
subscription_service.dart      class SubscriptionService
subscription_provider.dart
date_helper.dart               class DateHelper
```

One public class per file. The file name matches the class name in `snake_case`.

## File length

- **Hard cap: 300 lines per file.** Over it, split — extract widgets, views or helpers.
- A `build()` method over ~80 lines means a missing widget. Extract it.
- Long files are the failure mode this project exists to avoid. Splitting is never optional.

## Language

- **All code in English**: class names, variables, methods, file names, folders.
- **All comments in English.**
- Comments must be **short — one line**. Explain *why*, never *what*. If the code needs a
  paragraph to be understood, rewrite the code instead. No file headers, no doc blocks, no
  section banners, no commented-out code.

```dart
// Renewal is billed on the anniversary day, clamped to the month length.
```

## Reuse first

Before writing anything new:

1. Does it already exist in `ui/widgets/common/`, `core/helpers/` or `core/utils/`? Use it.
2. Does the Dart/Flutter stdlib cover it? Use it (`intl`, `DateTime`, `Iterable`, ...).
3. Does an already-installed dependency cover it? Use it.
4. Only then write it — as the smallest thing that works.

**Never add a dependency without asking the user first.** State what it replaces and why a
few lines of code are not enough.

## No speculative code

- No abstraction with a single implementation. No interface, no factory, no base class "for later".
- No config for a value that never changes.
- No empty scaffolding files, no placeholder features.
- Build exactly what the current feature needs.

## Theming

All colors, text styles, spacing, radii and motion come from `config/theme/`, and every token
there is specified in [DESIGN.md](DESIGN.md). **A widget that hardcodes a color, a size, a
radius or a duration is a bug.** Branch on `Theme.of(context).brightness`, not on a boolean flag.

## Definition of done

A change is done only when:

1. It does what was asked — no more.
2. `./scripts/format.sh` exits clean.
3. No file exceeds 300 lines.
4. Naming, layering and comment rules above are respected.
5. Nothing was committed (the user commits).
