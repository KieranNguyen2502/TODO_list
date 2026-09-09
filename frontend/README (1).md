# Frontend — Phase 3

## Dependencies to add
Your `pubspec.yaml` (from `flutter create`) doesn't have these yet — add them under `dependencies:`
(run `flutter pub add http flutter_secure_storage intl` from inside `frontend/`, or add manually and
run `flutter pub get`):

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  flutter_secure_storage: ^9.0.0
  intl: ^0.19.0
```

## What's here
```
frontend/lib/
├── main.dart                    App entry — bootstraps session, then shows the list
├── theme.dart                   Purple color palette / ThemeData
├── config/env.dart              API_BASE_URL, overridable via --dart-define
├── models/todo.dart             Todo model — matches backend fields exactly
├── services/todo_repository.dart Session token + every API call (no state-mgmt lib)
├── screens/todo_list_screen.dart Main screen: header, progress card, TO DO/COMPLETED, add sheet
└── widgets/todo_tile.dart       Single row: checkbox, strikethrough, delete
```

## Running it
```bash
cd frontend
flutter pub get

# emulator, local backend:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# physical device on same LAN, local backend:
flutter run --dart-define=API_BASE_URL=http://<your-host-LAN-IP>:8000

# against deployed backend (Phase 5):
flutter run --dart-define=API_BASE_URL=https://your-deployed-api.com
```
See `docs/environments.md` for the full matrix.

## Design decisions vs. the reference screenshot

Kept, because they map onto real backend fields or are pure presentation:
- Purple header, "My Tasks" title, current date
- Progress card (`done/total`, computed client-side from the loaded list — no backend field needed)
- TO DO / COMPLETED section split, driven by `todo.completed`
- Checkbox-circle toggle with strikethrough on completion
- Floating "+ New Task" button opening a bottom sheet

Dropped, because the backend has no matching field for them:
- **Priority (High/Medium/Low)** — not in the `todos` table. Adding it would mean touching the
  schema, the FastAPI models, and the update endpoint before the UI could show anything real —
  worth doing as a deliberate follow-up, not smuggled in as a frontend-only fake.
- **Due dates + "Overdue" banner** — same reasoning; no `due_date` column exists yet.
- **Bottom nav / Calendar tab** — there's only one screen's worth of functionality right now
  (a todo list). A nav bar with a single working destination is UI for a feature that doesn't exist.

If you want priority or due dates for real, that's a small, well-scoped follow-up: add the columns
in a new migration, extend `TodoCreate`/`TodoUpdate`/`TodoOut` in the backend, then extend the
`Todo` model and add a couple of fields to the add-task sheet. Worth doing once the current MVP
loop (create → complete → delete → restart → persist) is fully working end to end.

## Implementation notes
- **No state-management package** (Provider/Riverpod/Bloc) — one screen, one repository class,
  plain `setState`. Revisit if/when the app grows past this screen.
- **Optimistic UI** on toggle and delete — the checkbox flips and the row disappears immediately,
  and only reverts if the API call actually fails. Matters on a mobile network where a round trip
  can take a few hundred ms and a laggy checkbox feels broken even when it isn't.
- **Session bootstrap is a `FutureBuilder` at the app root** — nothing renders the todo list until
  `ensureSession()` resolves, so there's never a UI state where a request could go out without a token.
