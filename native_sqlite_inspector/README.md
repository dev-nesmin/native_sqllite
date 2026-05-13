# native_sqlite_inspector

A web-based DevTools-style inspector for `native_sqlite`. Connects to a running Flutter debug app via the VM service and lets you browse tables, run SQL queries, and edit or delete individual rows in real time.

---

## How it works

1. Your Flutter app opens a database with `native_sqlite` in debug mode and prints an Inspector URL to the console:
   ```
   ╔══════════════════════════════════════════════════════╗
   ║  Native SQLite Inspector is available at:            ║
   ║  http://dev-nesmin.github.io/native_sqllite/#/PORT/TOKEN ║
   ╚══════════════════════════════════════════════════════╝
   ```
2. Open the URL in a browser.
3. The inspector connects to the VM service WebSocket, discovers all open databases, and streams live data.

---

## Features

- **Table browser** — list all tables and paginate through rows
- **SQL console** — run arbitrary `SELECT`, `INSERT`, `UPDATE`, or `DELETE` statements
- **Row editor** — click any row to edit field values in place
- **Row deletion** — delete individual rows; works with any primary key name
- **Schema panel** — view `CREATE TABLE` SQL for each table

---

## Stack

| Layer | Library |
|-------|---------|
| Routing | `go_router` |
| State | `provider` |
| VM connection | `vm_service` + `web_socket_channel` |
| UI fonts | `google_fonts` |

---

## Running locally

```bash
cd native_sqlite_inspector
flutter run -d chrome
```

The inspector is a standalone Flutter web app — it does not need to be embedded in your own app.

---

## Related packages

| Package | Role |
|---------|------|
| [`native_sqlite`](../native_sqlite/native_sqlite/) | Plugin that exposes the VM service extension |
