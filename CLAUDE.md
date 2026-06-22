# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Source of truth

Requirements and the committed design live in [docs/Challenge brief.md](docs/Challenge%20brief.md) and [docs/Analysis and design.md](docs/Analysis%20and%20design.md). **Read both before implementing** — they define the architecture, identity/dedup/tombstone decisions, API notes, and testing strategy. Don't restate them here; link to them.

In short: a SwiftUI + SwiftData app that lists deduplicated random users from `randomuser.me` (infinite scroll, name/email filter, detail view), persistent across sessions including deletions.

## Invariants (correctness — don't drift)

The design doc has the full rationale; these few must stay in context every session:

- **IMPORTANT:** identity is `login.uuid` (`@Attribute(.unique)`). Never `email` or `id.value`.
- **IMPORTANT:** deleted users must not reappear — persist tombstones and filter incoming users before insert.
- **IMPORTANT:** stable order via an incremental `sortOrder` set at first insert; never mutate it on upsert.
- **IMPORTANT:** HTTPS only; model against the live API shape (street/dob/registered are objects; `login.uuid` exists), not the brief's sample.
- Never make the `@Model` `Codable` — decode a separate `UserDTO` and map it.

## Build / Run / Test

Scheme is RandomUser. Raw CLI from repo root:

```bash
# Build / run all tests
xcodebuild -project RandomUser.xcodeproj -scheme RandomUser \
  -destination 'platform=iOS Simulator,name=iPhone 16' build   # or: test

# Single test
xcodebuild test -project RandomUser.xcodeproj -scheme RandomUser \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:RandomUserTests/RandomUserTests/example
```

## Conventions

- **Swift Testing** (`import Testing`, `@Test`, `#expect`), not XCTest. Test setup uses `ModelConfiguration(isStoredInMemoryOnly: true)` + a mocked `APIClient`. UI tests are out of scope for now — focus on the repository merge, DTO decoding, and filter (see the design doc's testing strategy).
- Plain SwiftUI + SwiftData, **not TCA** (despite the global stack notes).
- New `@Model` types go in [RandomUser/](RandomUser/) and must be registered in the `Schema([...])` array in [RandomUserApp.swift](RandomUser/RandomUserApp.swift).
- **Commits:** Conventional Commits (`feat:`, `fix:`, `test:`, `refactor:`, `docs:`, `chore:`), imperative mood, descriptive. One commit per logical change — never a single giant commit. Add tests in the same commit as (or right after) the feature they cover.