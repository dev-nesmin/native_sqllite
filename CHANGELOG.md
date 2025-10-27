# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Fixed generator file extension mismatch: Changed from `.table.g.dart` to `.g.dart` to match part statements in model files
- Updated example project SDK constraint to match other packages (3.6.0)
- Updated build_runner to ^2.10.1 and flutter_lints to ^5.0.0 in example project

### Changed
- Updated documentation to reflect correct file extensions for generated files

## [0.0.1] - 2024-10-27

### Added
- Initial release
- Cross-platform SQLite plugin for Flutter (Android, iOS, Web)
- Automatic code generation for type-safe repositories
- Native code generation (Kotlin, Swift) for background tasks
- WAL mode support for concurrent access
- Full null-safety and compile-time checking
