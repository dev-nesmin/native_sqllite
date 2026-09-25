import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Detects another example tab through the browser BroadcastChannel API.
final class WebTabGuard {
  /// Creates a tab guard with a unique per-page identity.
  WebTabGuard() : _id = DateTime.now().microsecondsSinceEpoch.toString();

  static const _channelName = 'native_sqlite_example_tab_guard';

  final String _id;
  final StreamController<bool> _changes = StreamController<bool>.broadcast();
  web.BroadcastChannel? _channel;
  bool _anotherTabIsOpen = false;

  /// Whether another tab has answered this tab's presence probe.
  bool get anotherTabIsOpen => _anotherTabIsOpen;

  /// Emits when another tab is first detected.
  Stream<bool> get changes => _changes.stream;

  /// Opens the channel and announces this tab.
  void start() {
    if (_channel != null) return;
    final channel = web.BroadcastChannel(_channelName);
    _channel = channel;
    channel.addEventListener(
      'message',
      ((web.Event event) {
        final data = (event as web.MessageEvent).data;
        if (data == null || !data.isA<JSString>()) return;
        final message = (data as JSString).toDart;
        if (message == 'hello:$_id' || message == 'present:$_id') return;
        if (message.startsWith('hello:')) {
          channel.postMessage('present:$_id'.toJS);
        } else if (message.startsWith('present:')) {
          _setAnotherTabOpen();
        }
      }).toJS,
    );
    channel.postMessage('hello:$_id'.toJS);
  }

  /// Reloads the browser page.
  void reloadPage() => web.window.location.reload();

  void _setAnotherTabOpen() {
    if (_anotherTabIsOpen) return;
    _anotherTabIsOpen = true;
    _changes.add(true);
  }

  /// Closes the broadcast channel and event stream.
  void dispose() {
    _channel?.close();
    _channel = null;
    unawaited(_changes.close());
  }
}
