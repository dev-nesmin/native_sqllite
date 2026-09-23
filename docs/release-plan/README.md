# native_sqlite — release plan

The complete plan for taking native_sqlite (7 packages, example app,
inspector) from its current state to a publish-ready product on pub.dev.
Written for AI coding agents executing the work and for the maintainer who
reviews it.

Baseline: commit `64d1dca` on `main` (Flutter 3.47.5). Findings come from
five independent code audits (runtime/platforms, generator/CLI, inspector,
example app/annotations, release engineering), `flutter pub publish
--dry-run` on every package, and runs on an iOS simulator, an Android
emulator and Chrome. Key claims were re-verified in the code before being
written down.

---

## How to use this plan (agents)

1. Read, in order:
   1. [00-agent-operating-manual.md](00-agent-operating-manual.md) —
      environment, commands, **running on already-open iOS simulator /
      Android emulator / web browser**, rules, definition of done.
   2. [01-architecture-and-invariants.md](01-architecture-and-invariants.md)
      — how the system works and what must never break.
   3. The file that contains your task:
      [02-plugin-work-plan.md](02-plugin-work-plan.md) (runtime, API,
      generator, annotations, inspector, platforms, plugin tests, docs),
      [03-example-app-and-testing.md](03-example-app-and-testing.md)
      (example app and test harness),
      [04-release-and-publishing.md](04-release-and-publishing.md)
      (packaging, CI, publishing).
2. Pick the first task in the [execution order](#execution-order) whose
   dependencies are done and whose decisions are answered. Don't start a task
   that depends on an unanswered decision — ask the human.
3. Work only inside the task's scope. Things you notice outside it go into
   [Discovered issues](#discovered-issues).
4. Finish with the definition of done (manual §6) and set the task's status
   in the [task index](#task-index) (`todo` → `in progress` → `done`, or
   `blocked: <reason>`).

Task format: every task has an ID, a priority, evidence (file:line), what to
do, and acceptance criteria that must be checked by running something.

**Priorities:** **P0** blocks the first publish (bug, crash, data risk, legal
blocker, or an API that can't change later) · **P1** needed for a good first
release · **P2** before 1.0 · **P3** later.

**First release = 0.1.0** (recommended, D-05) when every P0 and P1 task is
done or explicitly deferred by the maintainer.

---

## State in one paragraph

The core works on Android, iOS and web: versioned migrations with identical
semantics on every platform, typed Kotlin/Swift generation, Dart↔native
sharing, integration tests passing on all three targets. But **nothing can be
published yet** (no LICENSE, `publish_to: none`, undeclared dependency,
no CHANGELOG, no example inside a package), and the audits found serious
issues: all database work runs on the platform main thread; Android binds
query arguments as strings; the database-name API has no handle and no real
transactions; the generator produces non-compiling code for common model
shapes (getters, `hashCode`, UUID keys) and invalid SQL for a class named
`Order`; watch mode deletes `database_manager.dart`; the migration history
depends on the working directory; most raw-SQL demos in the example fail at
runtime; the inspector's link rarely connects and its SQL console can delete
rows from the wrong table; there is no CI.

---

## Decisions needed

Answer these before the tasks that depend on them. Recommendations are the
plan's default if the maintainer agrees. Answered decisions are final for
agents; `open` means ask the maintainer before starting a task it blocks.
D-01, D-02, D-03 and D-09 were answered by the maintainer on 2026-09-24.

| ID | Question | Recommendation | Blocks | Answer |
|---|---|---|---|---|
| D-01 | License? | BSD-3-Clause (Flutter ecosystem standard) or MIT; holder "Nesmin", 2025–2026 | REL-03 | ✅ **BSD-3-Clause** (holder "Nesmin", 2025–2026 unless the maintainer says otherwise) |
| D-02 | Rename the GitHub repo `native_sqllite` → `native_sqlite` before the first publish? | Yes (GitHub redirects git/web URLs) | REL-06 | ✅ **Rename to `native_sqlite`** — the maintainer renames it on GitHub; then REL-06 updates every URL |
| D-03 | How to ship the inspector? | Flutter DevTools extension inside `native_sqlite`; retire the GitHub Pages app and the Firebase config | INS-02, REL-06 | ✅ **DevTools extension** (INS-02); retire the GitHub Pages app and the Firebase config |
| D-04 | Was the inspector connection code adapted from Isar Inspector (Apache-2.0)? | If yes: add NOTICE + keep license headers | REL-03, INS-* | open |
| D-05 | First version? | 0.1.0 for all 7 packages, released together; 1.0 after the API is frozen and CI is green (REL-15) | REL-04 | open |
| D-06 | Publisher and contact identity? | Verified publisher `nesmin.dev`; one contact email everywhere | REL-12, REL-13 | open |
| D-07 | Minimum toolchain / Android requirements? | Flutter ≥ 3.44 / Dart ≥ 3.12 on all packages; AGP 9 built-in Kotlin (document; don't support AGP 8); plugin `minSdk 24`, document that generated Kotlin helpers need `minSdk 26` or desugaring | RT-15, REL-04 | open |
| D-08 | Upgrade web to `sqlite3` 3.x? | Measure first (its build hook would also run in Android/iOS app builds); if the size impact is acceptable, upgrade; otherwise stay on 2.x for 0.1.0 | REL-09, RT-11 | open |
| D-09 | Replace the name-string API with a database handle + interactive transactions + batch **before** the first publish? | Yes — it's free now and breaking later | API-01…04 | ✅ **Yes, before the first publish** (API-01…API-04) |
| D-10 | Platforms for 0.1.0? | Android, iOS, web; macOS (PLT-01) right after; Windows/Linux later | PLT-*, EX-04 | open |
| D-11 | `.claude/settings.json` is tracked (also on `origin/main`) with local paths — keep or untrack? | Untrack + ignore (maintainer's call) | REL-02 | open |
| D-12 | Remove the committed Apple team id `GL866QHKF8` from the example Xcode project? | Yes | REL-07, EX-14 | open |
| D-13 | `graphify-out/` (231 files) is in the unpushed commit `64d1dca`: amend that commit or remove it in a new commit? | Amend (keeps it out of history) | REL-01 | open |
| D-14 | Commit the workspace `pubspec.lock`? | Yes (reproducible CI and app builds; pub never publishes it) | REL-02 | open |
| D-15 | Where does the example live? | Move to `native_sqlite/native_sqlite/example/` + `example/example.md` | REL-07 | open |
| D-16 | Annotation API changes before publish (rename `Index`/`Ignore`/`TypeConverter` to avoid clashes; enums for FK actions/SQL types; typed defaults; one way to ignore)? | Yes, all before 0.1.0 | ANN-02, API-03 | open |
| D-17 | `@EnumField` default storage? | `name` (reordering constants can't corrupt data) | ANN-03, GEN-11 | open |
| D-18 | Multiple databases (`@DbTable(database:)`)? | Reject with a clear build error in 0.1.0; implement later | GEN-05 | open |
| D-19 | Migration workflow? | Explicit: build fails when models differ from the latest snapshot; `migrations create` CLI records a version; history in a dedicated folder read through build_runner; opt-in `auto_version` for prototyping | GEN-06 | open |
| D-20 | `DateTime` semantics? The stored epoch milliseconds can't record whether the app wrote a UTC or a local value. | Keep millisecond storage; read back as local time by default (today's behavior, same as drift); add an option to read as UTC; document that UTC values compare equal only after `.toUtc()` | GEN-13 | open |
| D-21 | CLI scope? | Keep `generate` + `migrations create|verify|sql`; delete `export`, `migrate`, `analyze`, `stats`, cache commands | GEN-23 | open |

---

## Execution order

Phases are ordered; tasks inside a phase can run in parallel unless the
task lists a dependency.

**Phase 0 — Decisions and housekeeping**
Remaining open decisions answered (D-01, D-02, D-03, D-09 are decided) ·
maintainer renames the GitHub repo to `native_sqlite` (D-02) · REL-01 ·
REL-02 · TOOL-01

**Phase 1 — Publish blockers and fast correctness fixes**
REL-03 · REL-04 · REL-05 · GEN-02 · GEN-01 · GEN-03 · GEN-04 · GEN-09 ·
GEN-08 · RT-02 · RT-04 · RT-06 · RT-07 · RT-14 · RT-15 · ANN-01 · INS-01 ·
EX-01 · EX-02 · EX-03 · EX-04 · EX-05

**Phase 2 — Runtime architecture and public API** (D-09)
RT-08 · RT-01 · API-01 · API-02 · API-03 · API-04 · RT-03 · RT-05 ·
API-06 · TST-01 · TST-03

**Phase 3 — Generator workflow and correctness**
GEN-06 · GEN-07 · GEN-05 · GEN-10 · GEN-11 · GEN-12 · GEN-13 · GEN-14 ·
GEN-15 · GEN-16 · GEN-17 · GEN-18 · GEN-20 · GEN-21 · GEN-22 · GEN-23 ·
GEN-24 · GEN-25 · GEN-26 · ANN-02 · ANN-03 · ANN-05

**Phase 4 — Example app, tests and CI**
EX-06 … EX-18 · RT-09 · RT-10 · RT-11 · RT-12 · RT-13 · API-05 · TST-02 ·
REL-11

**Phase 5 — Inspector** (D-03)
INS-02 · INS-03 · INS-04 · INS-05 · INS-06 · INS-08 · INS-09

**Phase 6 — Documentation and release**
DOC-01 · DOC-02 · DOC-03 · REL-06 · REL-07 · REL-08 · REL-09 · REL-10 ·
REL-12 · REL-13 · REL-14 · pre-publish checklist
([04 §3](04-release-and-publishing.md#3-pre-publish-checklist-run-in-order))

**After 0.1.0 (P2/P3)**
EX-19…EX-24 · API-07 · API-08 · API-09 · GEN-19 · ANN-04 · PLT-01 ·
PLT-02 · PLT-03 · INS-07 · REL-15

---

## Task index

Status values: `todo`, `in progress`, `done`, `blocked: <reason>`.

### Tooling, runtime, API ([02](02-plugin-work-plan.md))

| ID | Task | Pri | Depends | Status |
|---|---|---|---|---|
| TOOL-01 | Helper scripts `tool/devices.sh`, `tool/test_generator.sh` | P1 | – | todo |
| RT-01 | All SQLite work off the platform main thread | P0 | RT-08, API-02 | todo |
| RT-02 | Android: typed argument binding | P0 | – | todo |
| RT-03 | Correct `execute` results; insert rowid | P0 | RT-02 | todo |
| RT-04 | iOS: surface step errors, no crash on empty SQL | P0 | – | todo |
| RT-05 | Typed, consistent errors (`NativeSqliteException`) | P0 | – | todo |
| RT-06 | One statement per SQL string everywhere | P0 | – | todo |
| RT-07 | Android: don't `closeAll` on engine detach | P0 | – | todo |
| RT-08 | Open is idempotent; fix iOS handle races | P0 | – | todo |
| RT-09 | Android correctness details | P1 | RT-02 | todo |
| RT-10 | iOS correctness details (busy timeout, …) | P1 | RT-04 | todo |
| RT-11 | Web correctness details | P1 | D-08 | todo |
| RT-12 | Database names and locations (validation, path, App Groups) | P1 | API-01 | todo |
| RT-13 | SQLite versions per platform | P1 | – | todo |
| RT-14 | `DatabaseConfig`/`QueryResult` value semantics | P1 | – | todo |
| RT-15 | Android build requirements (minSdk, AGP) | P0 | D-07 | todo |
| API-01 | Database handle instead of name strings | P0 | D-09 | todo |
| API-02 | Interactive transactions and batch with arguments | P0 | API-01, RT-01 | todo |
| API-03 | Narrow and clean the exports | P0 | D-16 | todo |
| API-04 | Consistent contracts (throw, no sentinels) | P0 | RT-05 | todo |
| API-05 | Background isolates | P1 | RT-01 | todo |
| API-06 | Real SQLite backend for `flutter test` | P1 | API-01 | todo |
| API-07 | Change notifications / reactive queries | P2 | API-01 | todo |
| API-08 | Smaller API gaps (upsert, exists, read-only, …) | P2 | API-01 | todo |
| API-09 | Encryption (SQLCipher variant) | P3 | – | todo |

### Generator and annotations ([02](02-plugin-work-plan.md))

| ID | Task | Pri | Depends | Status |
|---|---|---|---|---|
| GEN-01 | Correct code for real-world model shapes | P0 | – | todo |
| GEN-02 | Watch mode deletes `database_manager.dart` (`_hasRun`) | P0 | – | todo |
| GEN-03 | Quote SQL identifiers everywhere | P0 | – | todo |
| GEN-04 | UUID primary keys | P0 | – | todo |
| GEN-05 | One database-name setting; multi-DB decision | P0 | D-18 | todo |
| GEN-06 | Explicit, hermetic migration workflow | P0 | D-19 | todo |
| GEN-07 | Deterministic output (no timestamps/churn) | P0 | – | todo |
| GEN-08 | Fail loudly instead of generating wrong code | P0 | – | todo |
| GEN-09 | Reject composite primary keys (implement later) | P0 | – | todo |
| GEN-10 | Index API matches documentation | P1 | – | todo |
| GEN-11 | Enums (`EnumType.value`, reorder safety) | P1 | D-17 | todo |
| GEN-12 | Type converters (storage type, constructor args) | P1 | – | todo |
| GEN-13 | Value codecs (DateTime, JSON, declared types) | P1 | D-20 | todo |
| GEN-14 | Query builder fixes (+ `toSql()`) | P1 | – | todo |
| GEN-15 | No imports forced on users by part files | P1 | – | todo |
| GEN-16 | `auto: false` applies everywhere | P1 | – | todo |
| GEN-17 | Migration gaps (defaults, enum storage, renames, custom steps) | P1 | GEN-06 | todo |
| GEN-18 | Native output hygiene | P1 | – | todo |
| GEN-19 | Builder scope and performance | P2 | GEN-06 | todo |
| GEN-20 | Configuration surface | P1 | – | todo |
| GEN-21 | Remove the build cache | P1 | – | todo |
| GEN-22 | Dead code, duplication, leftovers | P1 | – | todo |
| GEN-23 | CLI rewrite | P1 | D-21, GEN-06 | todo |
| GEN-24 | Tests that prove generated code works | P1 | – | todo |
| GEN-25 | Logging and generated runtime noise | P1 | – | todo |
| GEN-26 | Generator public library surface | P1 | – | todo |
| ANN-01 | Annotation docs that break builds | P0 | GEN-04, GEN-10 | todo |
| ANN-02 | Annotation API shape | P1 | D-16 | todo |
| ANN-03 | `EnumField` default | P1 | D-17 | todo |
| ANN-04 | Expected annotations (roadmap) | P2 | – | todo |
| ANN-05 | Annotations package quality | P1 | REL-04 | todo |

### Inspector, platforms, tests, docs ([02](02-plugin-work-plan.md))

| ID | Task | Pri | Depends | Status |
|---|---|---|---|---|
| INS-01 | Minimum inspector safety (debug-only, opt-out, quoting, …) | P0 | – | todo |
| INS-02 | Ship as a DevTools extension | P1 | D-03 | todo |
| INS-03 | Protocol handshake and contract tests | P1 | INS-02 | todo |
| INS-04 | SQL console correctness | P1 | – | todo |
| INS-05 | Row identity for edit/delete | P1 | – | todo |
| INS-06 | Implement or delete phantom features | P1 | – | todo |
| INS-07 | Live data and robustness | P2 | INS-02 | todo |
| INS-08 | Inspector code quality | P1 | – | todo |
| INS-09 | Inspector documentation | P1 | INS-02 | todo |
| PLT-01 | macOS via shared Darwin sources | P2 | D-10 | todo |
| PLT-02 | Windows/Linux via FFI | P3 | API-06 | todo |
| PLT-03 | iOS App Groups / extensions | P2 | RT-12 | todo |
| TST-01 | Cross-platform conformance suite | P0 | – | todo |
| TST-02 | Native unit tests (Kotlin + Swift) | P1 | – | todo |
| TST-03 | Dart unit tests that check behavior | P1 | – | todo |
| DOC-01 | Make every documented statement true | P0 | – | todo |
| DOC-02 | Missing guides | P1 | – | todo |
| DOC-03 | API docs | P1 | REL-08 | todo |

### Example app ([03](03-example-app-and-testing.md))

| ID | Task | Pri | Depends | Status |
|---|---|---|---|---|
| EX-01 | Raw SQL uses real column names | P0 | – | todo |
| EX-02 | Native Integration screen doesn't crash on web | P0 | – | todo |
| EX-03 | Content hidden under the app bar | P0 | – | todo |
| EX-04 | Remove `macos/` (or macOS support) | P0 | D-10 | todo |
| EX-05 | One database-name source; honest status | P0 | GEN-05 | todo |
| EX-06 | Safe transactions and batch demos | P0 | API-02 | todo |
| EX-07 | App architecture and UX foundation | P1 | – | todo |
| EX-08 | CRUD screen correctness | P1 | RT-05 | todo |
| EX-09 | Orders & transactions screen | P1 | API-02 | todo |
| EX-10 | Query Builder playground | P1 | GEN-14 | todo |
| EX-11 | Model gallery (every type and annotation) | P1 | GEN-04, GEN-12 | todo |
| EX-12 | Raw API & errors screen | P1 | RT-05, API-01 | todo |
| EX-13 | Sample data and reset | P1 | API-02 | todo |
| EX-14 | Platform metadata and branding | P1 | D-12 | todo |
| EX-15 | Code hygiene | P1 | – | todo |
| EX-16 | Example README and `example.md` | P1 | REL-07 | todo |
| EX-17 | Migrations Lab (real schema v2) | P1 | GEN-06 | todo |
| EX-18 | Background Sync — native writes while app is closed | P1 | RT-01, RT-08 | todo |
| EX-19 | Native opens first | P2 | RT-08 | todo |
| EX-20 | Web persistence demo | P2 | – | todo |
| EX-21 | Inspector card | P2 | INS-02 | todo |
| EX-22 | Benchmarks screen | P2 | API-02 | todo |
| EX-23 | Background Dart isolate demo | P2 | API-05 | todo |
| EX-24 | Android home-screen widget | P2 | – | todo |

### Release engineering ([04](04-release-and-publishing.md))

| ID | Task | Pri | Depends | Status |
|---|---|---|---|---|
| REL-01 | Remove `graphify-out/` from the repo | P0 | D-13 | todo |
| REL-02 | Repository hygiene (.DS_Store, lockfile, scripts, refs) | P0 | D-11, D-14 | todo |
| REL-03 | License in root and all packages | P0 | D-01, D-04 | todo |
| REL-04 | Make packages publishable (pubspec fixes) | P0 | D-05, D-07 | todo |
| REL-05 | CHANGELOG.md in every package | P0 | REL-04 | todo |
| REL-06 | Settle repository name and all URLs | P0 | D-02, D-03 | todo |
| REL-07 | Example inside the app-facing package | P0 | D-15, D-12 | todo |
| REL-08 | Lints, formatting, API docs | P1 | – | todo |
| REL-09 | Dependency upgrades (analyzer, sqlite3, …) | P1 | D-08 | todo |
| REL-10 | Fix melos configuration | P1 | REL-04 | todo |
| REL-11 | Continuous integration | P1 | GEN-07 | todo |
| REL-12 | Automated publishing | P1 | D-06, REL-11 | todo |
| REL-13 | Community files and repo settings | P1 | D-06 | todo |
| REL-14 | Package README polish for pub.dev | P1 | REL-06 | todo |
| REL-15 | Versioning policy and 1.0 criteria | P2 | – | todo |

---

## Discovered issues

Agents: add anything you find outside your task's scope here (don't fix it
in the same task). The maintainer triages it into a task.

| Date | Found during | File:line | Issue | Suggested priority |
|---|---|---|---|---|
| | | | | |
