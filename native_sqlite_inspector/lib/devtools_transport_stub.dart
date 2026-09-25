abstract interface class DevToolsTransport {
  Future<Object?> call(String method, Map<String, Object?> args);

  Future<void> start({
    required void Function() onDataChanged,
    required void Function() onMainIsolateChanged,
  });

  Future<void> dispose();
}

DevToolsTransport createDevToolsTransport() => _UnsupportedDevToolsTransport();

final class _UnsupportedDevToolsTransport implements DevToolsTransport {
  @override
  Future<Object?> call(String method, Map<String, Object?> args) {
    throw UnsupportedError('The DevTools transport is available only on web.');
  }

  @override
  Future<void> start({
    required void Function() onDataChanged,
    required void Function() onMainIsolateChanged,
  }) {
    throw UnsupportedError('The DevTools transport is available only on web.');
  }

  @override
  Future<void> dispose() async {}
}
