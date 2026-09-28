# 04 — Release engineering and publishing

Everything needed to publish the seven packages on pub.dev with a good pana
score and an automated, repeatable release process. Task format and rules:
see [README.md](README.md) and
[00-agent-operating-manual.md](00-agent-operating-manual.md).

Evidence was gathered at `64d1dca` with `flutter pub publish --dry-run` on
every package, `flutter pub outdated`, `dart format --output=none`, analyzer
runs with lints enabled (on copies), and the GitHub/pub.dev APIs.

---

## 1. Where we stand

**No package can be published today.** Dry-run results:

| Package | Hard errors | Warnings |
|---|---|---|
| native_sqlite_annotations | no LICENSE | no CHANGELOG |
| native_sqlite_platform_interface | no LICENSE; `publish_to: none` | no CHANGELOG |
| native_sqlite_android / _ios / _web | no LICENSE; `publish_to: none` | `any` constraint on platform interface; no CHANGELOG |
| native_sqlite | no LICENSE; `publish_to: none` | 5 × `any` constraints; no CHANGELOG |
| native_sqlite_generator | no LICENSE; `publish_to: none`; imports `pub_semver` without declaring it (`lib/src/helpers/code_formatter.dart:2`) | `any` on annotations; `test` imported by 14 test files but not a dev dependency; no CHANGELOG |

Other facts:

- All 7 package names are **free** on pub.dev (API returns 404).
- Git remote: `https://github.com/dev-nesmin/native_sqllite` (typo "sqllite").
  **Decided (D-02): the repo is renamed to `native_sqlite`** before the first
  publish. `main` is 2 commits ahead of `origin` (`64d1dca` not pushed).
- Estimated pana after the blockers are fixed: ~115–135 / 160 per package
  (missing example, CHANGELOG, lints, outdated `analyzer`/`sqlite3`).

---

## 2. Tasks

Priorities: **P0** blocks publishing · **P1** needed for a good first
release · **P2** before 1.0.

### REL-01 · P0 · Remove the `graphify-out/` folder from the repository

- **Why:** 233 generated files of a local analysis cache, many containing local
  absolute paths. They were originally added by unpushed commit `761f511`.
- **Done:** the five unpushed commits were rewritten, replacing `761f511` with
  `d5003d1` and removing `graphify-out/` from that entire range. The directory
  remains locally available and is ignored by the root `.gitignore`. Recovery
  is available at `refs/backup/release-plan-before-history-rewrite-20260925`.
- **Acceptance:** `git ls-files graphify-out | wc -l` → 0; folder still
  exists locally.
- **Decision:** D-13 resolved by the maintainer: rewrite the unpushed history.

### REL-02 · P0 · Repository hygiene

- **Do:**
  - `.gitignore:1` ignores only `/.DS_Store` → change to `.DS_Store`, then
    `git rm --cached` the tracked `.DS_Store` files inside
    `native_sqlite/native_sqlite_android` and `native_sqlite/native_sqlite_ios`.
  - Remove the stale lockfile comment and the dead `!example/pubspec.lock`
    exception (`.gitignore:16-19`); **commit the root `pubspec.lock`**
    (D-14) so CI and app builds are reproducible (pub never publishes it).
  - `flutter_manager.sh` (14 KB) duplicates the melos scripts: delete it or
    move it to `tool/` and document it.
  - `.claude/settings.json` was removed from `origin/main` and is absent in
    the current checkout → human decides (D-11) whether to ignore `.claude/`
    so local settings cannot be reintroduced.
  - `git fetch --prune` to drop stale `origin/claude/*`, `origin/copilot/*`
    refs.
- **Acceptance:** `git status` clean after a full build of every target;
  `git ls-files | grep -E '\.DS_Store|graphify-out'` empty.

### REL-03 · P0 · License (all packages + root)

- **Decided (D-01): BSD-3-Clause.** Copyright line:
  `Copyright (c) 2025-2026, Nesmin` (the maintainer may change the holder
  name; ask before publishing if unsure). Use the standard BSD-3-Clause text
  from https://opensource.org/license/bsd-3-clause unchanged apart from the
  copyright line.
- **Do:** identical `LICENSE` in the repo root and in each of the 7 package
  directories (real files, not symlinks). `native_sqlite_ios.podspec:9`
  already points to `../LICENSE` → it will resolve. If D-04 confirms the
  inspector connection code was adapted from Isar Inspector (Apache-2.0),
  add a `NOTICE` and keep the upstream license header in those files.
- **Acceptance:** `flutter pub publish --dry-run` shows no LICENSE error in
  any package; CI check that all copies are byte-identical
  (`sha256sum */LICENSE */*/LICENSE LICENSE | awk '{print $1}' | sort -u | wc -l` → 1).

### REL-04 · P0 · Make the packages publishable (pubspec fixes)

For all 7 publishable packages:

1. Delete `publish_to: none` (6 packages). Don't replace it with a URL.
2. Version **0.1.0** everywhere (D-05); sibling constraints `^0.1.0`
   instead of `any` (`native_sqlite/pubspec.yaml:25-29`, implementations'
   dependency on the platform interface, generator → annotations).
3. `native_sqlite_generator`: add `pub_semver` to `dependencies` (used in
   `lib/`), add `test` (and `lints`) to `dev_dependencies`.
4. `native_sqlite_annotations`: add `dev_dependencies: lints, test`.
5. Align SDK constraints: `Package.swift` depends on `../FlutterFramework`
   (Flutter ≥ 3.44 plugin template) and `native_sqlite_android` already says
   `flutter: '>=3.44.0'` → set `environment: sdk: ^3.12.0, flutter: '>=3.44.0'`
   on every Flutter package and `sdk: ^3.12.0` on the pure Dart ones — or
   test and document an older floor. Decision D-07.
6. Metadata on every package: `repository:` (exact sub-path, pana clones it:
   `https://github.com/<owner>/<repo>/tree/main/<package path>`),
   `issue_tracker:`, `topics:` (≤ 5, e.g. `sqlite, database, storage,
   codegen, orm`), keep `homepage` only if it's about the package.
7. Descriptions of 60–180 chars (too short today: android 39, ios 35, web 54,
   annotations 40). Example: *"Android implementation of native_sqlite:
   SQLite shared by Flutter and native Kotlin code, with versioned
   migrations."*
- **Acceptance:** `flutter pub publish --dry-run` in every package →
  "Package has 0 warnings."

### REL-05 · P0 · CHANGELOG.md in every package

- **Do:** `## 0.1.0` entry summarizing the initial feature set per package
  (hand-written for the first release). Keep a common style so
  `melos version` can append later entries.
- **Acceptance:** dry-run no longer warns about CHANGELOG.

### REL-06 · P0 · Update every URL for the renamed repository (before first publish)

- **Decided (D-02, D-03):** the GitHub repository becomes
  `https://github.com/dev-nesmin/native_sqlite`, and the inspector ships as a
  DevTools extension (INS-02), so **no hosted inspector URL is compiled into
  the package at all**.
- **Precondition (human):** the maintainer renames the repository on GitHub
  (Settings → General → Repository name). Don't start until that is done;
  then run `git remote set-url origin https://github.com/dev-nesmin/native_sqlite.git`.
- **Why:** URLs are baked into published code and docs:
  `inspector_connect.dart:19` (`http://dev-nesmin.github.io/native_sqllite/`),
  melos `repository: https://github.com/nesmin/native_sqllite` (404, wrong
  owner), generator error links `https://github.com/dev-nesmin/native_sqlite`
  (`generator_errors.dart:55-187`, 404), CLI help
  `https://github.com/your_repo/native_sqlite`
  (`bin/native_sqlite_generator.dart:157`), deploy workflow base-href.
- **Do:** replace every URL with the new repository URL (grep for
  `sqllite`, `nesmin/`, `your_repo`, `web.app`, `github.io`); use `https://`
  only. Remove `.github/workflows/deploy-inspector.yml`,
  `native_sqlite_inspector/firebase.json` and `.firebaserc` together with
  INS-02 (the hosted app is retired). Check whether an old build is still
  live at `native-sqllite.web.app` and ask the maintainer to disable it.
- **Acceptance:** `git grep -nE 'sqllite|your_repo|nesmin/native'` returns
  only intended hits; every URL in pubspecs/READMEs/code returns 200.

### REL-07 · P0 · Example inside the app-facing package

- **Why:** pana awards 10 points per package for an example, and pub.dev's
  Example tab shows `example/` of the published package only. The app lives
  at the repo root today, outside every package.
- **Needs human:** D-15. Recommended: move `example/` →
  `native_sqlite/native_sqlite/example/` (standard Flutter plugin layout),
  update the root `workspace:` list, `.github` paths, docs and the
  operating manual paths. Add `example/example.md` (pana reads it first) with
  a compact walkthrough: model → build_runner → repository/query builder →
  Kotlin/Swift snippet.
- For the other 6 packages add a short `example/README.md` or
  `example/main.dart` (annotations + generator: annotated model and
  `build.yaml`; platform packages: "use `native_sqlite`" with a snippet).
- Remove the committed Apple team id `DEVELOPMENT_TEAM = GL866QHKF8`
  (`example/ios/Runner.xcodeproj/project.pbxproj:493,678,701`, D-12) — it
  would be published inside `native_sqlite`.
- **Acceptance:** dry-run of `native_sqlite` lists `example/…`; pana's
  "Provide documentation → example" check passes.

### REL-08 · P1 · Lints, formatting and API docs

- **Do:**
  - Add `analysis_options.yaml` to every package (only `native_sqlite` has
    one): `flutter_lints` for Flutter packages, `package:lints/recommended`
    for Dart packages; enable `strict-casts`, `strict-inference`,
    `strict-raw-types`, and lints `public_member_api_docs`,
    `unawaited_futures`, `discarded_futures`.
  - Fix the resulting issues (known before strictness: generator 36 infos,
    annotations 3, platform interface 1 — `unnecessary_library_name`,
    `unintended_html_in_doc_comment`, `depend_on_referenced_packages`,
    `unnecessary_string_escapes`, …).
  - `dart format` all non-generated sources (35 files in the packages would
    change today; also example 5, inspector 7).
  - Exclude generated code from analysis where appropriate
    (`**/*.g.dart`, `**/*.freezed.dart`, `**/*.table.dart` in the example).
- **Acceptance:** `flutter analyze --fatal-infos` clean in every package;
  `dart format --output=none --set-exit-if-changed` clean.

### REL-09 · P1 · Dependency upgrades that pana scores

| Dependency | Now | Target | Notes |
|---|---|---|---|
| `analyzer` (generator) | `^8.4.0` (8.4.1) | `>=13.3.0 <15.0.0` | Breaking AST APIs used by the CLI (`ClassDeclaration.members`, `NamedExpression` in `lib/src/cli/{analyze,stats,export}_command.dart`); builders mostly unaffected. Raise `source_gen`, `build`, `dart_style` lower bounds to match; verify with `dart pub downgrade`. Inside the workspace Flutter pins `test_api`, which caps `test`/`analyzer` below 14 — pana resolves standalone and will get 14.x. |
| `sqlite3` (web) | `^2.9.3` | `^3.x` — **decision D-08** | 3.x moves native loading to build hooks. Because `native_sqlite` depends on `native_sqlite_web` on every platform, the hook would also run in Android/iOS app builds (downloading/bundling SQLite) unless apps set a user-define. `dispose()` → `close()` deprecations; new `sqlite3.wasm`. Measure APK/IPA size impact before adopting; otherwise stay on 2.x for 0.1.0 and accept −10 pana points. |
| example: `freezed`, `json_serializable` | 3.2.3 / 6.11.2 | latest | unblocked by the analyzer upgrade |
| inspector: `go_router`, `web_socket_channel`, `google_fonts`, `provider` | old / unused | remove | the DevTools extension (INS-02, decided D-03) replaces routing and the raw WebSocket client; `google_fonts`/`provider` are unused |

- **Acceptance:** `flutter pub outdated` shows no direct dependency of a
  publishable package constrained below its latest version (except any
  documented decision); all tests green.

### REL-10 · P1 · Fix the melos configuration

- **Evidence:** root `pubspec.yaml` `melos:` section.
  - `publish:` script runs `melos publish` → in melos 7 a script with a
    built-in command's name overrides it → infinite self-invocation;
    `publish:dry` calls the same script with `--dry-run`, which fails.
  - `format` and `clean` scripts also shadow built-ins.
  - `repository: https://github.com/nesmin/native_sqllite` → 404.
  - `test` is filtered to Flutter packages, so the generator's 14 test files
    never run through melos.
  - melos skips `publish_to: none` packages when versioning (fixed by REL-04).
- **Do:** delete `publish`/`publish:dry` (use built-in `melos publish` /
  `melos publish --no-dry-run --git-tag-version`); rename `format`/`clean`
  scripts (e.g. `fmt`, `clean:all`); add `test:generator` using the direct
  runner from the operating manual; set `command.version` (`branch: main`,
  `linkToCommits: true`, message template); correct the repository URL.
  Document `dart run melos …` (melos is not on PATH).
- **Acceptance:** `dart run melos run test:all` (or equivalent) runs every
  suite; `dart run melos publish` performs a dry run of all 7 packages.

### REL-11 · P1 · Continuous integration

Create `.github/workflows/ci.yml` (Flutter 3.47.5 via
`subosito/flutter-action`, actions pinned to SHAs like the existing
workflow, `concurrency` cancel-in-progress, `permissions: contents: read`).

| Job | Runner | Steps |
|---|---|---|
| `analyze` | ubuntu | `flutter pub get`; per package `flutter analyze --fatal-infos`; `dart format --output=none --set-exit-if-changed` on non-generated sources |
| `test-dart` | ubuntu | `flutter test` in `native_sqlite`; generator via the direct runner: `dart --packages=.dart_tool/package_config.json "$(jq -r '.packages[]\|select(.name=="test").rootUri' .dart_tool/package_config.json \| sed 's#file://##')/bin/test.dart"` (run from the generator dir with `../.dart_tool/...`) |
| `generator-standalone` | ubuntu | copy the generator + annotations to a temp dir, drop `resolution: workspace`, `dart pub get && dart test`, then `dart pub downgrade && dart analyze` (mimics pana's lower-bound check) |
| `codegen-up-to-date` | ubuntu | run build_runner in the example; `git diff --exit-code` (requires timestamp-free output, GEN-07) |
| `android` | ubuntu | `flutter build apk --debug` (example); `./gradlew :native_sqlite_android:testDebugUnitTest` |
| `android-integration` | ubuntu (KVM) | `reactivecircus/android-emulator-runner` (API 26 and 36): `flutter test integration_test` |
| `ios` | macos | `flutter build ios --simulator --debug --no-codesign` twice: CocoaPods (default) and SPM (per-project `flutter: config: enable-swift-package-manager: true` set by the job) |
| `ios-integration` | macos | boot a simulator (`xcrun simctl boot`), `flutter test integration_test -d <udid>` |
| `web` | ubuntu | `flutter build web`; chromedriver + `flutter drive -d web-server --browser-name=chrome --headless` |
| `devtools-extension` | ubuntu | build the inspector with `devtools_extensions build_and_copy` and run `devtools_extensions validate --package=native_sqlite/native_sqlite`; fail if the committed `extension/devtools/build` is stale (INS-02) |
| `publish-dry-run` | ubuntu | matrix over 7 packages: `flutter pub publish --dry-run` must report 0 warnings |
| `pana` | ubuntu | after first release (siblings resolvable from pub.dev) run pana per package with `--exit-code-threshold`; before that only on leaf packages |

Also: `dependabot.yml` (pub, github-actions, gradle), `CODEOWNERS`, issue
templates (bug: platform, Flutter version, package versions, repro; feature),
PR template (conventional title, CHANGELOG/test checkboxes), and ask the
human to protect `main` and release tags.

- **Acceptance:** a PR runs all jobs green; a deliberately broken commit
  (format error, failing test) turns CI red.

### REL-12 · P1 · Automated publishing

1. Human (D-06): create verified publisher (recommended `nesmin.dev`, DNS
   TXT via Google Search Console).
2. **First release by hand** (automated publishing can only be enabled for
   existing packages), in dependency order:
   1. `native_sqlite_annotations`
   2. `native_sqlite_platform_interface`
   3. `native_sqlite_android`, `native_sqlite_ios`, `native_sqlite_web`
   4. `native_sqlite`
   5. `native_sqlite_generator`
   Each from a clean CI-equivalent checkout (pub respects `.gitignore` only
   inside a git checkout — never publish from a copy containing `build/`).
3. Transfer each package to the publisher; enable "Automated publishing from
   GitHub Actions": repository, tag pattern `<package>-v{{version}}`,
   required environment `pub.dev`.
4. `.github/workflows/publish.yml`: `on: push: tags: ['*-v[0-9]*']`,
   `permissions: id-token: write`, environment `pub.dev`; steps: checkout →
   `dart-lang/setup-dart@v1` (for the OIDC credential) →
   `subosito/flutter-action` (the workspace contains Flutter packages, so the
   Dart-only reusable workflow cannot resolve it) → map tag prefix to the
   package directory → `flutter pub publish --dry-run` →
   `flutter pub publish --force`.
5. Tags must be pushed by a person (workflow-created tags don't trigger
   workflows); push them in dependency order.
- **Acceptance:** releasing 0.1.1 of one package via tag succeeds end to end.

### REL-13 · P1 · Community files and repository settings

- Root `README.md`: badges (pub version, pub points, CI, license), license
  section, supported-platform table, links to each package.
- `CONTRIBUTING.md` (setup with puro, commands from the operating manual,
  conventional commits, how to regenerate the example),
  `CODE_OF_CONDUCT.md`, `SECURITY.md` (private reporting; inspector
  security notes).
- Human: GitHub repo description, topics, homepage.
- Unify contact identity (D-06): git author `dev.nesmin@gmail.com`, podspec
  `dev@nesmin.dev`, homepage `nesmin.dev`.

### REL-14 · P1 · Package README polish for pub.dev

- Replace relative links (`../native_sqlite/`, `../../../native_sqlite_generator/`)
  with absolute pub.dev / GitHub links (relative links break on pub.dev).
- Fix install snippets (`^1.0.0` → the real version) in the root,
  `native_sqlite` and generator READMEs.
- Each platform package README: "endorsed implementation, don't depend on
  it directly", platform requirements (minSdk, iOS 13, `sqlite3.wasm`).
- Add screenshots (pubspec `screenshots:`) of the example/inspector.

### REL-15 · P2 · Versioning policy and 1.0 criteria

- 0.x until: the handle-based API (API tasks in
  [02-plugin-work-plan.md](02-plugin-work-plan.md)) is final, CI is green on
  Android/iOS/web including integration tests, the migration guarantees are
  documented, and at least one 0.x release was exercised through the
  automated pipeline.
- Conventional-commit PR titles with package scopes; squash merges;
  `melos version` from the second release on (first changelog by hand).
- Podspec `s.version`: keep in sync via a small script in the release job or
  document it as static.

---

## 3. Pre-publish checklist (run in order)

1. Decisions D-01…D-22 answered (see [README.md](README.md#decisions-needed);
   D-01, D-02, D-03 and D-09 are already decided).
2. The GitHub repository is renamed to `native_sqlite` (D-02), and REL-01,
   REL-02, REL-03, REL-04, REL-05, REL-06, REL-07 are done.
3. All P0 tasks in [02-plugin-work-plan.md](02-plugin-work-plan.md) done.
4. Example app P0 tasks in [03-example-app-and-testing.md](03-example-app-and-testing.md) done.
5. CI green on a clean checkout (REL-11), including integration tests on
   Android, iOS and web.
6. `flutter pub publish --dry-run` → 0 warnings for all 7 packages.
7. pana on the leaf packages ≥ 140/160; fix what's actionable.
8. Human approves the exact versions and CHANGELOGs.
9. Human publishes by hand in dependency order (REL-12 step 2) and pushes
   the tags.
10. Verify on pub.dev: scores, platform tags, example tab, README rendering,
    links; install into a fresh `flutter create` app on Android, iOS and web
    following only the published README.
