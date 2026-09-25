import 'dart:async';

/// No-op tab guard used by non-web builds.
final class WebTabGuard {
  /// Creates a no-op guard.
  WebTabGuard();

  /// Always false outside a browser.
  bool get anotherTabIsOpen => false;

  /// Emits no events outside a browser.
  Stream<bool> get changes => const Stream<bool>.empty();

  /// Starts the guard.
  void start() {}

  /// Reloads the current page when supported.
  void reloadPage() {}

  /// Releases browser resources.
  void dispose() {}
}
