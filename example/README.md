# native_sqlite example

This application demonstrates the Dart API, generated repositories and query
builders, native Kotlin/Swift access, migrations, background work, web
persistence, the DevTools inspector, and host-side SQLite tests.

## Prerequisites

- Puro with the repository-pinned Flutter 3.47.5 toolchain
- Java 17 or newer and Android SDK 36 for Android builds
- Xcode and CocoaPods for iOS builds
- Chrome for the web example and browser integration tests

The current Android example and generated Kotlin helpers require minSdk 26.
The final published lower bound is tracked as D-07 in the release plan.

## Generate and run

From the repository root:

```sh
puro flutter pub get
cd example
puro flutter pub run build_runner build
puro flutter run
```

`native_sqlite_config.yaml` is the single source for the database name and
native output directories. Generation writes Dart files under `lib/generated`
and `lib/models`, Kotlin under `android/app/src/main/kotlin`, and Swift under
`ios/Runner/Generated`. Do not edit those files by hand.

The iOS `Generated` directory is a synchronized Runner folder in Xcode, so
newly generated Swift files are compiled automatically. If recreating the
project, add that directory to the Runner target as a synchronized folder.

## WebAssembly

The web build loads `web/sqlite3.wasm`. The committed binary is the official
sqlite3 2.9.4 release asset and must match the version resolved in the root
lockfile. Verify it from the repository root:

```sh
puro dart run tool/check_web_wasm.dart
```

When updating sqlite3, download the matching asset from the
[sqlite3.dart releases](https://github.com/simolus3/sqlite3.dart/releases),
verify its digest, and update the check deliberately.

## Tests and builds

```sh
# Host unit and widget tests
puro flutter test

# Platform builds
puro flutter build apk --debug
puro flutter build ios --simulator --debug --no-codesign
puro flutter build web
```

Device integration tests are in `integration_test/database_test.dart`. Use an
emulator or simulator, never a physical device. The full commands for choosing
an already-running device are in the
[operating manual](../docs/release-plan/00-agent-operating-manual.md).

## DevTools inspector

Run the app in debug mode, open a database, then open Flutter DevTools. Enable
`native_sqlite` in the Extensions menu and select its tab. The extension can
browse schemas and rows, execute SQL with explicit write confirmation, and
edit or delete an identified row.

See [the package walkthrough](../native_sqlite/native_sqlite/example/example.md)
for a compact model-to-native-code example.
