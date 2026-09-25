# Versioning and compatibility

native_sqlite remains on 0.x releases until the handle API is stable, CI is
green on Android, iOS, and web (including integration tests), migration
guarantees are finalized and documented, and at least one 0.x release has
completed the automated publishing pipeline.

During 0.x, packages are released together and breaking changes increment the
minor version. After 1.0, the workspace follows semantic versioning. PR titles
use conventional commits with a package or area scope, for example
`fix(android): preserve typed bind arguments`. The repository uses squash
merges so the PR title becomes the release commit.

The first release receives hand-authored changelogs. Starting with the second
release, run `dart run melos version` from `main`; package tags use
`<package>-v<version>`. The iOS podspec version must match the package version.
CI runs `dart tool/check_package_versions.dart` before publishing.
