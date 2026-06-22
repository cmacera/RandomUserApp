# Analysis & Design — Random User Coding Challenge

Working notes capturing how I read the problem and the design decisions I'm committing to. Together with the challenge brief, this is the full picture I build from. Where the brief leaves room, decisions here are stated as explicit assumptions.

## Stack

Swift, SwiftUI, SwiftData, URLSession (`async/await`). Combine only for the search debounce (optional; an equivalent cancellable `Task` works too).

## Architecture

- **Local store (SwiftData) is the UI's source of truth.** The network only *adds* users; it never feeds the views directly.
- **`UserRepository` is the core.** It coordinates API + persistence and owns the merge logic (dedup + tombstones + `sortOrder`). This is the part worth testing.
- **`APIClient` behind a protocol, injected** — makes everything mockable.
- **`Decodable` DTO separate from the `@Model`.** Decode into `UserDTO`, map to `UserModel`. Don't make the `@Model` itself `Codable` (it couples the persistence schema to the API shape).
- **Reads: hybrid pattern.** `@Query` in the view for auto-reactive reads (sorted by `sortOrder`, predicate for the filter) + a light VM/service for commands (load more, delete, search). `@Query` is View-only — it can't live in the VM. The repository is still required for the write path.
- MVVM, deliberately avoiding over-engineering: no SPM packages, no VIPER for a problem this size. Balance modularity and readability.

## Identity & deduplication

- **Identity = `login.uuid`** → `@Attribute(.unique)` gives upsert-on-conflict for free.
- **Not `email`:** it's derived from the name, and name pools are finite, so two genuinely different users can collide on the same email → false merge. uuid fails on the safe side.
- Assumption to state: "same user = same `login.uuid`".

## API notes

- Model against the **live API**, not the brief's sample (the sample reflects an older API version). Verify with `https://randomuser.me/api/?results=5`.
- Live shape vs the brief's sample:
  - `location.street` is an object `{ number, name }`, not a string; `location` also carries `country`, `coordinates`, `timezone`.
  - `dob` and `registered` are objects `{ date, age }` with ISO8601 dates → `JSONDecoder.dateDecodingStrategy = .iso8601`.
  - `login.uuid` exists (it's absent from the brief's sample).
- Use **`https://`**. Plain `http` is blocked by **ATS (App Transport Security)** — iOS's default policy requiring TLS connections unless you add `Info.plist` exceptions, which I won't.
- Pagination: `?seed=X&page=N&results=M`.
  - Without a seed, `page` anchors nothing — each call is freshly random.
  - With a seed it's deterministic **only if `results` stays constant**, and the determinism is per API version.
  - The seed buys coherent pagination within a session (fewer incoming duplicates); it is *not* the mechanism for the persistence requirement.

## Persistence & ordering

- **Stable order is my responsibility.** SwiftData doesn't guarantee insertion order on fetch. I assign an incremental `sortOrder: Int` at first insert, always sort by it, and never touch it on upserts.
- **Deletion must survive the server.** Tombstones: a persistent record of deleted uuids (a `DeletedUser` model, or an `isDeleted` flag). On every merge, filter incoming users against the tombstones *before* inserting.

## Data flow

1. **Launch:** `@Query` renders whatever is already persisted immediately (offline-friendly). No network call needed on relaunch when data already exists.
2. **First run / load more:** request the next `page` → process (dedup + tombstone filter + assign `sortOrder`) → save. `@Query` refreshes the list automatically.
3. **Delete:** remove from the store *and* write a tombstone, so a later fetch can't bring the user back.
4. The local store always wins; the network is an append-only feed into it.

Guards and concurrency:
- An `isLoading` flag + a page cursor prevent the scroll trigger from firing duplicate page requests. The cursor must be known across launches (persisted, or derived from the current count).
- A background `@ModelActor` for the merge is optional at this volume (40/page); doing it on the main context is simpler and defensible. If I go background: never pass `@Model` instances across actors (map to value types) and confirm `@Query` refreshes after the background save.

## Search / filter

- Match by name / surname / email, case-insensitive, partial.
- **Debounce** the input ("once the user stops typing"): a Combine `.debounce` on `searchText`, or a cancellable `Task` + `Task.sleep`.
- **Composing `@Query` with the Combine debounce:** they sit in different layers and compose cleanly. `@Query` is the reactive data source; Combine only controls *when* the search term changes. The debounced term then either drives an in-memory `.filter` over the `@Query` array (simplest, fine for this dataset) or is passed into a subview that rebuilds a `@Query(filter: #Predicate { ... })` so filtering happens at the store level.

## Testing strategy

The riskiest logic is the merge, so the tests concentrate there:

- **Repository merge** (highest signal): a response with duplicates + an already-stored user + a uuid in the tombstones → exactly one stored, the deleted user does not reappear, order preserved.
- **Tombstone / persistent deletion:** delete, re-fetch the same user, it stays gone.
- **Stable ordering** across several merges.
- **DTO decoding**, including the `id.value == null` case.
- **Filter:** case-insensitive, partial, across name/surname/email.
- Setup: `ModelConfiguration(isStoredInMemoryOnly: true)` + a mocked `APIClient`. Using Swift Testing (`@Test` / `#expect`).
- One happy-path UI test (load → tap → detail → delete); no further investment there.

## Delivery

- Public git repo, descriptive commits.
- README stating assumptions explicitly (uuid as identity, in-memory filtering, live API vs the outdated brief sample, seed usage) and crediting any template I start from.