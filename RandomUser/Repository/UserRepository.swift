//
//  UserRepository.swift
//  RandomUser
//

import Foundation
import OSLog
import SwiftData

/// Coordinates the API and the local store, and owns the merge logic (dedup +
/// tombstones + stable `sortOrder`). The local store is the UI's source of truth;
/// the network only ever *adds* users.
///
/// `@MainActor` on the main `ModelContext`: at this volume (40/page) merging on the
/// main context is the simpler, defensible choice — the cost that mattered (network +
/// JSON decoding) already runs off-main inside the `APIClient`.
final class UserRepository: UserRepositoryProtocol {
    private let apiClient: APIClient
    private let context: ModelContext
    private let seed: String
    private let pageSize: Int
    
    private let logger = Logger(subsystem: "com.cmacera.RandomUser", category: "Repository")

    /// Page cursor for the *current session*. Not persisted: on relaunch `@Query`
    /// shows the stored users with no fetch, and a fresh seed + page 1 simply yields
    /// new random users, deduped against what's already stored. The seed buys coherent
    /// pagination within a session; it is not the persistence mechanism.
    private var nextPage = 1

    /// Repository-level guard against overlapping page loads (e.g. the infinite-scroll
    /// trigger firing twice). The view model owns the loading state the UI observes.
    private var isLoading = false

    init(
        apiClient: APIClient,
        context: ModelContext,
        seed: String = UUID().uuidString,
        pageSize: Int = 40
    ) {
        self.apiClient = apiClient
        self.context = context
        self.seed = seed
        self.pageSize = pageSize
    }

    /// Fetches the next page and merges it into the store. No-op while a load is
    /// already in flight.
    func loadNextPage() async throws {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let dtos = try await apiClient.fetchUsers(seed: seed, page: nextPage, results: pageSize)
        try merge(dtos)
        nextPage += 1
    }

    /// Removes a user and writes a tombstone so a later fetch can't bring it back.
    func delete(_ user: UserModel) throws {
        context.insert(DeletedUser(uuid: user.uuid, deletedAt: Date()))
        context.delete(user)
        try context.save()
    }

    // MARK: - Merge

    /// Inserts only users that are neither tombstoned nor already stored (and dedups
    /// repeats within the same batch), assigning each a new incremental `sortOrder`.
    /// Existing users are left untouched — their `sortOrder` never changes.
    private func merge(_ dtos: [UserDTO]) throws {
        let tombstoned = try tombstonedUUIDs()
        var seen = try storedUUIDs()
        var order = try nextSortOrder()

        for dto in dtos {
            let uuid = dto.login.uuid
            guard !tombstoned.contains(uuid), !seen.contains(uuid) else { continue }
            seen.insert(uuid)
            context.insert(dto.toModel(sortOrder: order))
            order += 1
        }

        try context.save()

        logger.debug("""
            merge: fetched \(dtos.count, privacy: .public), \
            inserted \(inserted, privacy: .public), \
            skipped(tombstoned) \(skippedTombstoned, privacy: .public), \
            skipped(duplicate) \(dtos.count - inserted - skippedTombstoned, privacy: .public), \
            tombstones \(tombstoned.count, privacy: .public), \
            total \(seen.count, privacy: .public)
            """)
    }

    private func tombstonedUUIDs() throws -> Set<String> {
        let deleted = try context.fetch(FetchDescriptor<DeletedUser>())
        return Set(deleted.map(\.uuid))
    }

    private func storedUUIDs() throws -> Set<String> {
        let users = try context.fetch(FetchDescriptor<UserModel>())
        return Set(users.map(\.uuid))
    }

    /// One past the current highest `sortOrder` (0 when the store is empty), so new
    /// users append after everything — including past gaps left by deletions.
    private func nextSortOrder() throws -> Int {
        var descriptor = FetchDescriptor<UserModel>(
            sortBy: [SortDescriptor(\.sortOrder, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let highest = try context.fetch(descriptor).first?.sortOrder ?? -1
        return highest + 1
    }
}
