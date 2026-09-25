import 'dart:async';
import 'dart:convert';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:native_sqlite/inspector_protocol.dart';

abstract interface class DevToolsTransport {
  Future<Object?> call(String method, Map<String, Object?> args);

  Future<void> start({
    required void Function() onDataChanged,
    required void Function() onMainIsolateChanged,
  });

  Future<void> dispose();
}

DevToolsTransport createDevToolsTransport() => _WebDevToolsTransport();

final class _WebDevToolsTransport implements DevToolsTransport {
  StreamSubscription<dynamic>? _extensionEvents;
  VoidCallback? _mainIsolateListener;

  @override
  Future<Object?> call(String method, Map<String, Object?> args) async {
    final response = await serviceManager.callServiceExtensionOnMainIsolate(
      method,
      args: {if (args.isNotEmpty) 'args': jsonEncode(args)},
    );
    return response.json?['result'];
  }

  @override
  Future<void> start({
    required void Function() onDataChanged,
    required void Function() onMainIsolateChanged,
  }) async {
    final service = serviceManager.service;
    if (service == null) {
      throw StateError('DevTools is not connected to an app.');
    }
    try {
      await service.streamListen('Extension');
    } catch (_) {
      // DevTools normally subscribes first; duplicate subscriptions are safe.
    }
    _extensionEvents = service.onExtensionEvent.listen((event) {
      if (event.extensionKind ==
          NativeSqliteInspectorProtocol.dataChangedEvent) {
        onDataChanged();
      }
    });
    _mainIsolateListener = onMainIsolateChanged;
    serviceManager.isolateManager.mainIsolate.addListener(onMainIsolateChanged);
  }

  @override
  Future<void> dispose() async {
    final listener = _mainIsolateListener;
    if (listener != null) {
      serviceManager.isolateManager.mainIsolate.removeListener(listener);
    }
    await _extensionEvents?.cancel();
  }
}
