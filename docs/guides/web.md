# Web setup and persistence

The web implementation runs SQLite in WebAssembly and flushes its virtual file
system to IndexedDB before a mutating API call completes.

Copy the `sqlite3.wasm` file matching the resolved `sqlite3` package version
into the application's `web/` directory. A missing or mismatched file causes
the first open to fail.

```text
my_app/
  web/
    index.html
    sqlite3.wasm
```

WAL is unavailable in browsers, so the backend uses MEMORY journal mode.
Custom native directories and iOS App Groups are rejected. Each browser tab
has its own in-memory SQLite instance backed by the same IndexedDB storage;
use one active tab per database. The example's `/web` route demonstrates a
persistent launch counter and a `BroadcastChannel` warning for a second tab.

To verify persistence, run the app, change data, reload the page, and read the
same row. Test the second-tab warning separately; do not write from both tabs.
