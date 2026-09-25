# Contributing to native_sqlite

Thank you for helping improve native_sqlite. Changes should keep the Dart API,
Android, iOS, web, generated code, and documentation consistent.

## Setup

The repository pins Flutter with [Puro](https://puro.dev/). Install Puro, then
run from the repository root:

```sh
puro flutter pub get
puro flutter pub run melos run analyze --no-select
puro flutter pub run melos run analyze:dart --no-select
puro flutter pub run melos run test:all --no-select
```

Android builds require Java 17 or newer. Building the iOS example requires
Xcode and CocoaPods. See the
[agent operating manual](docs/release-plan/00-agent-operating-manual.md) for
the verified toolchain and device commands.

## Making changes

- Open an issue for substantial API, migration, or generator design changes.
- Use conventional commit or PR-title prefixes such as `feat:`, `fix:`,
  `docs:`, `test:`, or `chore:`.
- Add focused tests for behavior changes and keep platform behavior aligned.
- Update documentation and examples when public behavior changes.
- Do not include credentials, VM-service URIs, database contents, signing
  identities, or machine-specific paths.

Generated Dart, Kotlin, Swift, and schema files must be regenerated rather
than edited by hand:

```sh
cd example
puro flutter pub run build_runner build
cd ..
./tool/test_generated_code.sh
```

Review generated diffs carefully. Never rewrite or delete committed migration
snapshots unless the migration design explicitly requires it.

## Before opening a pull request

Run the aggregate tests and the builds relevant to your change. At minimum:

```sh
puro flutter pub run melos run test:all --no-select
./tool/test_generated_code.sh
git diff --check
```

Use the pull-request checklist and explain any platform or integration test
that could not be run. Report security issues privately as described in
[SECURITY.md](SECURITY.md).
