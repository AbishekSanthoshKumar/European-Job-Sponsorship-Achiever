# EUROPEAN DREAM

*Track every step towards your European career.*

A personal job-search operating system for securing a visa-sponsored Software
Engineer position in Europe. Flutter web, Android and iOS from one codebase.

## Run it

```bash
flutter pub get
flutter run -d chrome     # web
flutter run                # connected device / simulator
```

On first launch the app imports your target database and generates today's
plan automatically. No setup, no accounts, no network required.

## Your target database

Every company, agency, job board and portal from the files you supplied is
baked into `assets/data/seed_targets.json` — **1,239 unique records** from
1,391 source rows (152 were the same organisation appearing in more than one
of your files, merged so each keeps the richest data of all its sources).

| Source | What it contributed |
|---|---|
| `AIH … Google Drive` sheet 1 | 694 German companies, with industry, city, career page, LinkedIn |
| `AIH … Google Drive` sheet 2 | 266 companies across DE/UK/IE/AT/NL/BE + 44 recruiters |
| `AIH … Google Drive` sheet 3 | 142 visa-sponsor sites, boards and agencies |
| `Netherlands Hiring Companies.xlsx` | 100 NL companies with career-page links |
| `germany.txt`, `netherlands.txt` | Curated priority shortlists |
| `country wise companies.txt`, `luxembourg.txt` | Staffing agencies per country |
| Infographics + screenshot | 10 government portals, 10 local boards, 5 recruiter databases, 5 global staffing groups |

Companies by country: **Germany 782**, **Netherlands 118**, Ireland 32,
UK 30, Belgium 23, Austria 19, plus others.

A test (`test/seed_test.dart`) asserts named records from *every* source
survive the import, so nothing can silently go missing.

To rebuild the asset after editing anything in `source_data/`:

```bash
python3 tool/build_seed_data.py
```

## Strategy

Country allocation totals 100%, weighted to your two primary markets with a
deliberate spread elsewhere so an opportunity in a smaller market is never
ruled out:

- **Germany 45%**, **Netherlands 30%** — 75% combined
- Remaining 25% across Ireland, Poland, Sweden, Belgium, Austria,
  Switzerland, Denmark, Spain, Portugal, Estonia, Finland, Norway,
  Czechia, Luxembourg, Lithuania, Latvia, Italy, Romania, Malta, Cyprus

Editable at any time under **Countries → Edit targets**. The UK is included
but disabled by default (Skilled Worker visas need a licensed sponsor).

## What it does

**Mission Control** — countdown, mission status, today's weighted score ring,
streak, urgent items, and data-driven insights.
**Today** — plan auto-generated from weekly targets. A missed day is
*redistributed*, never duplicated (Strict / Flexible / Catch-up modes).
Completing a task asks "what did you do?" and records it to history.
**Applications** — Kanban with drag-and-drop, table and timeline views;
0–100 opportunity score weighted toward visa probability; aging detection
(Active → Waiting → Follow-up Due → Stale).
**Companies / Agencies / Networking** — CRMs over your imported lists, with
interaction timelines and quiet-contact detection.
**Opportunities** — paste a link in seconds, convert to an application later.
**Follow-ups** — auto-created when you apply, with copyable draft messages.
**Interviews** — prep checklists and a post-interview review database.
**Analytics** — funnel, country/role/source/resume performance, 30-day volume.
**History** — GitHub-style consistency heatmap; click any day to see it.
Also: Countries, Resumes (A/B response rates), Prep, Portfolio, Goals,
Resources (your playbook), Settings with CSV export.

`⌘K` / `Ctrl+K` opens the command palette on web and desktop.

## Architecture

```
lib/
  core/
    domain/      models, enums (persisted by string id, never index), settings
    data/        DataRepository interface, local store, seed loader
    services/    scoring, metrics, plan generator, streaks, insights
    theme/       dark-first design system
  features/      one folder per section
  shared/        reusable widgets, responsive shell, navigation
tool/            seed-data generator
```

State is Riverpod; every screen reads from providers over a
`DataRepository` interface.

### Moving to Supabase

Storage is **local-first** — it works offline on all three platforms with
zero configuration. Everything goes through the `DataRepository` interface
in `lib/core/data/repository.dart`, so cloud sync is one new implementation
plus one changed line in `AppBootstrap.load()`:

```dart
final repo = SupabaseDataRepository(url: ..., anonKey: ...);
```

No feature code changes. Nothing else in the app knows where data lives.

## Tests

```bash
flutter test test/logic_test.dart test/seed_test.dart   # 23 tests, fast
```

Covers plan redistribution across all three modes, opportunity scoring,
funnel reconstruction for closed applications, aging thresholds, streak
rules and rest days, and full seed-data coverage.

> `test/widget_test.dart` boots the whole app. It is slow because it loads
> all 1,239 seed records; `test/flutter_test_config.dart` disables
> `google_fonts` network fetching so it does not stall. Run it on its own
> with a generous timeout.
