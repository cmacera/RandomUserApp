# RandomUser

![CI](https://github.com/cmacera/RandomUserApp/actions/workflows/ci.yml/badge.svg)

A SwiftUI + SwiftData app that lists deduplicated random users from
[randomuser.me](https://randomuser.me): infinite scroll, name/email filter, detail
view, and swipe-to-delete — all persistent across sessions, deletions included.

> Full rationale for every decision below lives in
> [docs/Analysis and design.md](docs/Analysis%20and%20design.md); the original task is in
> [docs/Challenge brief.md](docs/Challenge%20brief.md). This README is the summary.

## Requirements

- Xcode 26.5, iOS 26.5 SDK
- Swift 6 language mode, SwiftUI, SwiftData, `async/await` URLSession

## Running

Open `RandomUser.xcodeproj`, select the **RandomUser** scheme, and run on an iOS 26.5
simulator. From the command line:

```bash
# Build
xcodebuild -project RandomUser.xcodeproj -scheme RandomUser \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Test
xcodebuild test -project RandomUser.xcodeproj -scheme RandomUser \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Features (per the brief)

- **List** of users with name, surname, email, phone, and photo.
- **Infinite scroll** that pages in more users.
- **No duplicates** — the same user is stored once.
- **Swipe-to-delete** that *sticks*: a deleted user never reappears, even in a later
  server response.
- **Search** by name, surname, or email — debounced, updated once you stop typing.
- **Detail view** (gender, name, location, registered date, email, photo).
- **Persistent across sessions**: the same users in the same order until deleted or the
  app is reinstalled.

## Architecture

MVVM, deliberately kept small (no SPM packages, no VIPER). The **SwiftData store is the
UI's source of truth**; the network only ever *adds* users.

```
View (@Query, sorted by sortOrder) ──filter──► UserListViewModel (search + commands)
        │                                              │ writes
        └────────────── reads ──────────┐              ▼
                                    SwiftData ◄──── UserRepository ──► APIClient ──► randomuser.me
                                                  (merge: dedup + tombstones + sortOrder)
```

- **`UserRepository`** owns the merge logic (the part worth testing) behind
  `UserRepositoryProtocol`.
- **`APIClient`** is behind a protocol and injected, so the repository is testable
  against a mock.
- **DTO ≠ `@Model`**: a `Decodable` `UserDTO` is decoded and mapped to `UserModel`,
  keeping the persistence schema decoupled from the API shape.
- **Reads** stay in the View via `@Query`; the view model owns the debounced search term
  and commands (load more, delete).

## Key decisions & assumptions

- **Identity is `login.uuid`** (`@Attribute(.unique)`), never `email` (derived from
  finite name pools → can collide) nor `id.value` (nullable, national-format-specific).
  uuid fails on the safe side.
- **Deletion uses tombstones**: a `DeletedUser` record per deleted uuid. The merge filters
  incoming users against tombstones *before* inserting, so a deleted user can't return.
- **Stable order** via an incremental `sortOrder` assigned once at first insert and never
  mutated on upsert (SwiftData doesn't guarantee fetch order otherwise).
- **HTTPS only** — no App Transport Security exceptions.
- **Pagination resumes across launches**: a persisted `PaginationState` (seed + next page)
  means load-more continues where it left off instead of restarting at page 1 — which
  would re-fetch already-stored pages.
- **Deduplication is defensive** and **proven by unit tests** that inject duplicate and
  tombstoned uuids.
- **Filtering is in-memory** over the `@Query` results (fine at this volume), matching
  name / surname / full name / email, case-insensitive and partial.
- **Concurrency**: Swift 6 language mode with MainActor-by-default. The network fetch and
  JSON decoding run off the main actor (`@concurrent` on the `APIClient`); persistence and
  UI stay on the MainActor.

## Testing

[Swift Testing](https://developer.apple.com/documentation/testing), with an in-memory
`ModelContainer` + a mocked `APIClient`. Coverage concentrates on the riskiest logic:

- **Repository merge** — dedup (within a batch and against the store), tombstone filtering,
  stable incremental `sortOrder`, and append-after-deletion.
- **Persistent deletion** — a deleted user stays gone across a re-fetch.
- **DTO decoding** — live API shape, ignored fields, ISO8601 dates.
- **Filter** — case-insensitive, partial, across name / surname / full name / email.
- **View model** — debounced search, plus the load-more and delete commands.
- **APIClient** — URL building, decoding, and HTTP-error mapping (via a `URLProtocol` stub).

UI tests are intentionally out of scope.

## CI

GitHub Actions builds and runs the test suite on every push (and PR) — see
[.github/workflows/ci.yml](.github/workflows/ci.yml).

## Credits

Bootstrapped from Xcode's **SwiftUI + SwiftData** app template and adapted to the task
(removed the sample `Item` model and the UI-test target). Data from
[randomuser.me](https://randomuser.me).
