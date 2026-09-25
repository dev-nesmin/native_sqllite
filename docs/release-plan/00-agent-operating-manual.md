# 00 — Agent operating manual

Read this file completely before starting any task in this plan. It tells you
how this repository is built, tested and run, which devices to use, and the
rules every task must follow. Task lists live in the other files of this
folder (see [README.md](README.md)).

Baseline: every statement in this plan was verified against commit `64d1dca`
on `main` (Flutter 3.47.5). If the code has moved on, re-verify a claim before
acting on it.

Decided by the maintainer (see [README.md § Decisions](README.md#decisions-needed)):
BSD-3-Clause license (D-01) · GitHub repo renamed to `native_sqlite` (D-02;
the maintainer renames it, then `git remote set-url origin
https://github.com/dev-nesmin/native_sqlite.git`) · inspector becomes a
DevTools extension (D-03) · database-handle API with interactive
transactions and batch before the first publish (D-09).

---

## 1. Golden rules

1. **Stay inside the task.** Each task has an ID, a scope and acceptance
   criteria. Do not fix unrelated things you notice; add them to
   [README.md § Discovered issues](README.md#discovered-issues) instead.
2. **Never hand-edit generated files.** Regenerate them (see §4.4). Generated
   files are:
   - `example/lib/models/*.table.dart`, `*.freezed.dart`, `*.g.dart`
   - `example/lib/generated/database_manager.dart`,
     `example/lib/generated/native_sqlite_schema.json`,
     `example/lib/generated/.native_sqlite_stamp`
   - `example/android/app/src/main/kotlin/com/example/native_sqlite_example/generated/**`
   - `example/ios/Runner/Generated/**`
3. **Never delete or rewrite migration history** —
   `example/lib/generated/schemas/native_sqlite_schema_v*.json`. These files
   are the source of the migration steps shipped to devices. If a task
   changes the example's models on purpose, it must say so and keep the
   resulting new `vN` file.
4. **Always go through puro.** The project pins Flutter 3.47.5 in
   `.puro.json`. Use `puro flutter …` and `puro dart …`, never a global
   `flutter`/`dart`.
5. **Only use emulators, simulators and browsers — never the physical
   device.** A physical iPhone (`00008150-…`, "nesmin") is often connected
   wirelessly. Select devices with `emulator == true` (see §5). Prefer
   devices that are **already running**; boot one only if none is open.
6. **Don't change global machine configuration.** No
   `flutter config --enable-…`, no global `pub global activate`, no Xcode
   or Android SDK changes. For experiments use per-project settings (e.g.
   `flutter: config: enable-swift-package-manager: true` in
   `example/pubspec.yaml`) and revert them.
7. **Ask the human before anything outward-facing or irreversible:**
   `pub publish` (without `--dry-run`), pushing, tagging, renaming the
   GitHub repository, choosing the license, choosing version numbers,
   deleting data on devices other than the example app's, adding paid
   services or secrets to CI.
8. **Commit discipline (only when the human allows commits):** one commit per
   task, message `type(scope): summary [TASK-ID]` (conventional commits:
   `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`, `build`).
9. **Leave the tree green:** a task is not done until §6 passes.

---

## 2. Environment (verified)

| Tool | Version / location |
|---|---|
| Flutter / Dart | 3.47.5 / 3.13.4 via puro (`.puro.json` → env `3.47.5`) |
| Xcode | 27.0 (build 27A266a) |
| CocoaPods | 1.16.2 (Homebrew). **Swift Package Manager is disabled globally** (`~/.config/flutter/settings`), so iOS builds use CocoaPods. The iOS plugin supports both. |
| Java | OpenJDK 21 |
| Android SDK | `$ANDROID_HOME` = `~/Library/Android/sdk`; `adb` at `$ANDROID_HOME/platform-tools/adb` |
| Android toolchain (example) | Gradle 9.3.1, AGP 9.1.0, built-in Kotlin (KGP 2.4.0 declared), compileSdk 36, plugin minSdk 26 |
| Node | v22 (only needed to download `chromedriver`) |
| sqlite3 CLI | 3.54 (`/usr/bin/sqlite3`), for inspecting pulled databases |
| jq | `/usr/bin/jq` |

App identifiers of the example:

| Platform | Identifier |
|---|---|
| Android `applicationId` | `com.example.native_sqlite_example` |
| iOS bundle id | `com.example.nativeSqliteExample` |
| Web | served from `example/build/web` (IndexedDB database `native_sqlite`) |
| Default database name | `example_app` (`example/native_sqlite_config.yaml` → `database_name`) |

---

## 3. Repository map

Dart pub **workspace** (root `pubspec.yaml`, `workspace:` list) — one
`pubspec.lock` and `.dart_tool/` at the root.

| Path | Package | Role | Published? |
|---|---|---|---|
| `native_sqlite/native_sqlite` | `native_sqlite` | App-facing API (`NativeSqlite`, `AutoMigration`, inspector hook). Re-exports the annotations. | yes |
| `native_sqlite/native_sqlite_platform_interface` | `native_sqlite_platform_interface` | `NativeSqlitePlatform`, `DatabaseConfig` (incl. versioned `migrations`), `QueryResult` | yes |
| `native_sqlite/native_sqlite_android` | `native_sqlite_android` | Kotlin: `NativeSqlitePlugin`, `NativeSqliteManager` (shared with native code), `DatabaseConfig` | yes |
| `native_sqlite/native_sqlite_ios` | `native_sqlite_ios` | Swift (SPM + CocoaPods layout under `ios/native_sqlite_ios/Sources/native_sqlite_ios`): `NativeSqlitePlugin`, `NativeSqliteManager`, `DatabaseConfig` | yes |
| `native_sqlite/native_sqlite_web` | `native_sqlite_web` | Dart: sqlite3 WASM + `IndexedDbFileSystem` | yes |
| `native_sqlite_annotations` | `native_sqlite_annotations` | `@DbTable`, `@PrimaryKey`, `@DbColumn`, … | yes |
| `native_sqlite_generator` | `native_sqlite_generator` | build_runner builders (`table`, `migration`, `schema_registry`, `native_code`) + CLI | yes |
| `native_sqlite_inspector` | — | Flutter web app ("Database Inspector"), today deployed to GitHub Pages; **becomes a DevTools extension shipped inside `native_sqlite`** (D-03, INS-02) | no (app) |
| `example` | — | Example app (Android, iOS, web; `macos/` exists but has no plugin implementation) | no (app) |

Builder pipeline (`native_sqlite_generator/build.yaml`): `migration`
(writes `lib/generated/native_sqlite_schema.json` + versioned snapshots) →
`schema_registry` (writes `lib/generated/database_manager.dart`) and
`native_code` (writes Kotlin/Swift into the app's `android/` and `ios/`) →
`table` (writes `*.table.dart` parts).

---

## 4. Command reference

Run everything from the repository root unless a `cd` is shown.

### 4.1 Dependencies

```bash
puro flutter pub get          # resolves the whole workspace
```

`dart pub …`, `dart run …` and plain `dart test` **fail** in this workspace
("native_sqlite_platform_interface requires the Flutter SDK"). Always use
the `puro flutter pub …` variants or the direct runners below.

### 4.2 Static analysis and formatting

```bash
for d in native_sqlite/native_sqlite native_sqlite/native_sqlite_platform_interface \
         native_sqlite/native_sqlite_android native_sqlite/native_sqlite_ios \
         native_sqlite/native_sqlite_web native_sqlite_annotations native_sqlite_generator \
         native_sqlite_inspector example; do
  printf '%-48s' "$d"; (cd "$d" && puro flutter analyze 2>&1 | grep -E 'issues found|No issues')
done

puro dart format --output=none --set-exit-if-changed <dir>   # check only
puro dart format <dir>                                        # apply (not on generated files)
```

### 4.3 Tests

```bash
# Generator (resolves the direct `test` runner from package_config.json)
tool/test_generator.sh

# Runtime package
cd native_sqlite/native_sqlite && puro flutter test

# Example unit + widget tests
cd example && puro flutter test

# Android plugin Kotlin unit tests (JUnit + Mockito)
cd example/android && ./gradlew :native_sqlite_android:testDebugUnitTest
# results: example/build/native_sqlite_android/test-results/testDebugUnitTest/*.xml
```

Integration tests (real devices/browsers) are in §5.

Baseline at `64d1dca`: generator 143/143, `native_sqlite` 79/79, example
3/3, Android plugin 5/5, integration 5/5 on iOS simulator, Android emulator
(API 36) and Chrome (4 + 1 skipped native-only test).

### 4.4 Code generation (example app)

```bash
cd example && puro flutter pub run build_runner build
```

- `--delete-conflicting-outputs` no longer exists in build_runner ≥ 2.10
  (it is ignored with a warning). Don't add it to docs or scripts.
- One build regenerates Dart, the schema snapshot, and the Kotlin/Swift files.
- After changing a generator template, regenerate and then **review the diff
  of the generated files** — that diff is the real test of the change.

### 4.5 Builds

```bash
cd example
puro flutter build apk --debug              # Android
puro flutter build ios --simulator --debug  # iOS simulator (CocoaPods)
puro flutter build web                      # Web (needs web/sqlite3.wasm)
cd ../native_sqlite_inspector && puro flutter build web
```

`example/build/` grows to ~2 GB; delete it if disk space gets low.

---

## 5. Running on already-open devices (iOS simulator, Android emulator, web)

Always reuse what is already running. Everything in this section was
executed successfully against an open iPhone 18 Pro simulator (iOS 27), an
open Android emulator (API 36) and Chrome 153.

### 5.1 Detect what is open

```bash
eval "$(tool/devices.sh)"
echo "iOS simulator: ${IOS_SIM:-none} | Android emulator: ${ANDROID_EMU:-none} | Chrome: ${WEB_CHROME:-none}"
```

The `emulator == true` filter is what excludes the physical iPhone. Faster
checks without Flutter:

```bash
xcrun simctl list devices booted -j | jq -r '.devices[][] | select(.state=="Booted") | "\(.name) \(.udid)"'
"$ANDROID_HOME/platform-tools/adb" devices | awk '/^emulator-/{print $1}'
```

`tool/devices.sh` only selects entries reported as emulators for Android and
iOS, so a connected physical device is never returned.

Only if nothing is open (and the task needs a device): boot one, then
re-run the detection.

```bash
xcrun simctl list devices available | grep iPhone     # pick a UDID
xcrun simctl boot <UDID> && open -a Simulator
puro flutter emulators                                 # e.g. "childdevice"
puro flutter emulators --launch childdevice
```

### 5.2 Run the example interactively (human at the keyboard)

```bash
cd example
puro flutter run -d "$IOS_SIM"
puro flutter run -d "$ANDROID_EMU"
puro flutter run -d chrome                  # Flutter opens its own Chrome window
```

### 5.3 Install and launch without an interactive session (agents)

`flutter run` stays attached, and `--no-resident` does not exist in
Flutter 3.47. Build, install over the existing app (keeps its data), launch:

```bash
cd example
# Android emulator
puro flutter build apk --debug
"$ANDROID_HOME/platform-tools/adb" -s "$ANDROID_EMU" install -r build/app/outputs/flutter-apk/app-debug.apk
"$ANDROID_HOME/platform-tools/adb" -s "$ANDROID_EMU" shell am start -W -n com.example.native_sqlite_example/.MainActivity

# iOS simulator
puro flutter build ios --simulator --debug
xcrun simctl install "$IOS_SIM" build/ios/iphonesimulator/Runner.app
xcrun simctl launch "$IOS_SIM" com.example.nativeSqliteExample
```

Fresh install (wipes the example's data): uninstall first with
`adb -s "$ANDROID_EMU" uninstall com.example.native_sqlite_example` /
`xcrun simctl uninstall "$IOS_SIM" com.example.nativeSqliteExample`.

**Upgrade testing (migrations):** build and install the *old* version, run
it and create data, then build the *new* version and install it **without
uninstalling**. That reproduces an app-store update.

### 5.4 Screenshots and logs

```bash
"$ANDROID_HOME/platform-tools/adb" -s "$ANDROID_EMU" exec-out screencap -p > /tmp/android.png
xcrun simctl io "$IOS_SIM" screenshot /tmp/ios.png

"$ANDROID_HOME/platform-tools/adb" -s "$ANDROID_EMU" logcat -s flutter NativeSqlite AndroidRuntime
xcrun simctl spawn "$IOS_SIM" log stream --level debug --predicate 'process == "Runner"'
```

Agents can read the PNGs to check UI (e.g. layout, error banners).

### 5.5 Integration tests on the open devices

```bash
cd example
puro flutter test integration_test -d "$IOS_SIM"
puro flutter test integration_test -d "$ANDROID_EMU"
```

⚠️ `flutter test` **uninstalls the app when it finishes** — the example's
database on that device is deleted. Reinstall with §5.3 afterwards if you
need the app.

Web (Chrome, headless) needs a `chromedriver` that matches the installed
Chrome:

```bash
CHROME_VERSION="$("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --version | awk '{print $3}')"
npx -y @puppeteer/browsers install "chromedriver@$CHROME_VERSION" --path "$HOME/.cache/native_sqlite/chromedriver"
CHROMEDRIVER="$(find "$HOME/.cache/native_sqlite/chromedriver" -name chromedriver -type f | head -1)"
"$CHROMEDRIVER" --port=4444 &            # keep running during the test
cd example && puro flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/database_test.dart \
  -d web-server --browser-name=chrome --headless
kill %1                                   # stop chromedriver
```

### 5.6 Web in an already-open browser

With hot reload (the human opens the URL in their existing browser tab):

```bash
cd example && puro flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8765
# then open http://127.0.0.1:8765 in the already-open browser
open -a "Google Chrome" http://127.0.0.1:8765      # or: open http://127.0.0.1:8765
```

Release build served statically (Python serves `.wasm` as
`application/wasm`, which sqlite3 needs):

```bash
cd example && puro flutter build web
python3 -m http.server 8765 --bind 127.0.0.1 --directory build/web &
open http://127.0.0.1:8765
```

Persistence check: create data, reload the tab, confirm it's still there.
Inspect storage in Chrome DevTools → Application → IndexedDB →
`native_sqlite`. Reset it with DevTools → Application → Storage → "Clear
site data".

### 5.7 Inspect the example's database on a device

```bash
# Android (debug builds only). Pull all three files: most recent data is in -wal.
mkdir -p /tmp/dbpull/android
for f in example_app.db example_app.db-wal example_app.db-shm; do
  "$ANDROID_HOME/platform-tools/adb" -s "$ANDROID_EMU" exec-out \
    run-as com.example.native_sqlite_example cat "databases/$f" > "/tmp/dbpull/android/$f"
done
sqlite3 /tmp/dbpull/android/example_app.db "PRAGMA user_version; SELECT name FROM sqlite_master WHERE type='table';"

# iOS simulator
C="$(xcrun simctl get_app_container "$IOS_SIM" com.example.nativeSqliteExample data)"
mkdir -p /tmp/dbpull/ios && cp "$C/Library/Application Support/NativeSqlite/"example_app.db* /tmp/dbpull/ios/
sqlite3 /tmp/dbpull/ios/example_app.db "PRAGMA user_version;"
```

Always work on copies; never open the live file on the device for writing.

---

## 6. Definition of done (every task)

A task is done only when all of these hold:

1. Its acceptance criteria are met, and each one was checked by running
   something (test, build, screenshot, SQL query), not by reading code.
2. `puro flutter analyze` reports **no issues** in every package the task
   touched, and `puro dart format --output=none --set-exit-if-changed` passes
   for the touched non-generated files.
3. The test suites in §4.3 that cover the touched packages pass; new
   behavior has new tests.
4. If generator templates changed: the example was regenerated (§4.4), the
   generated diff was reviewed, and the example still builds for Android,
   iOS simulator and web (§4.5).
5. If runtime/platform code changed: the integration tests pass on the open
   iOS simulator, Android emulator and in Chrome (§5.5).
6. Docs/README/CHANGELOG entries affected by the change are updated in the
   same task.
7. The task's status is updated in [README.md](README.md).

---

## 7. Known gotchas (learned the hard way)

- **Workspace + Flutter:** `dart pub/run/test` fail; use `puro flutter pub …`
  and the direct test runner (§4.3). `flutter test` inside
  `native_sqlite_generator` also fails for `build_test`-based tests
  (`Isolate.packageConfig` unsupported) — use the direct runner.
- **build_runner warning** "SDK language version 3.13.0 is newer than
  analyzer language version 3.11.0" — harmless until the analyzer upgrade
  task; don't try to silence it elsewhere.
- **iOS generated code** is compiled because `ios/Runner/Generated` is an
  Xcode *synchronized folder* (project format 77). Never add generated Swift
  files to the Xcode project individually.
- **Swift Package Manager experiments** add SPM wiring to
  `Runner.xcodeproj` that Flutter does not remove when SPM is turned off
  again. Revert by regenerating the iOS project
  (`flutter create --platforms=ios --org com.example --project-name native_sqlite_example .`
  after deleting `Runner.xcodeproj`, `Runner.xcworkspace`, `Pods`,
  `Podfile.lock`) and re-adding the `Generated` synchronized group.
- **Flutter channel values on iOS** arrive as `NSNull`,
  `FlutterStandardTypedData` and `NSNumber`; `NativeSqlitePlugin.swift`
  converts them before calling `NativeSqliteManager`. Keep the manager free
  of Flutter types — native code calls it directly.
- **Android:** the example and `native_sqlite_android` use AGP built-in
  Kotlin; do not re-add `id("kotlin-android")` / `kotlinOptions`.
- **Foreign keys must stay OFF during migrations** on every platform
  (rebuilding a parent table with FKs on cascade-deletes child rows). Any
  change to open/upgrade code must keep that and keep
  `PRAGMA foreign_key_check` before commit.
- **Migration history is data:** `lib/generated/schemas/*.json` must be
  committed; CI and every developer must build from the same history.
- **WAL:** pulled Android/iOS databases need their `-wal`/`-shm` files.
- **Web:** `web/sqlite3.wasm` must match the resolved `sqlite3` package
  version; one tab per database.
