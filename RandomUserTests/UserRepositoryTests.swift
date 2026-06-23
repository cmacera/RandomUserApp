//
//  UserRepositoryTests.swift
//  RandomUserTests
//

import Foundation
import SwiftData
import Testing
@testable import RandomUser

@Suite(.serialized)
@MainActor
struct UserRepositoryTests {

    /// Held as a stored property so the container outlives `context` for the whole
    /// test — a context whose `ModelContainer` has been deallocated traps on use.
    /// A fresh in-memory store is created per test (Swift Testing makes a new instance
    /// for each `@Test`).
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() throws {
        let schema = Schema([UserModel.self, DeletedUser.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
    }

    private func storedUsers(_ context: ModelContext) throws -> [UserModel] {
        try context.fetch(
            FetchDescriptor<UserModel>(sortBy: [SortDescriptor(\.sortOrder)])
        )
    }

    @Test("Merge dedups within a batch and against the store, and skips tombstoned uuids")
    func mergeDedupsAndRespectsTombstones() async throws {
        context.insert(DeletedUser(uuid: "deleted", deletedAt: Date()))
        try context.save()

        let page = [
            UserDTO.stub(uuid: "a"),
            UserDTO.stub(uuid: "a"),        // duplicate within the same batch
            UserDTO.stub(uuid: "deleted"),  // tombstoned
            UserDTO.stub(uuid: "b"),
        ]
        let repo = UserRepository(
            apiClient: MockAPIClient(pages: [page]), context: context, seed: "s"
        )

        try await repo.loadNextPage()

        let uuids = try storedUsers(context).map(\.uuid)
        #expect(Set(uuids) == ["a", "b"])
        #expect(uuids.count == 2)
    }

    @Test("A deleted user does not reappear when the server returns it again")
    func deletedUserDoesNotReappear() async throws {
        let api = MockAPIClient(pages: [
            [UserDTO.stub(uuid: "x")],
            [UserDTO.stub(uuid: "x")],  // same user comes back on the next page
        ])
        let repo = UserRepository(apiClient: api, context: context, seed: "s")

        try await repo.loadNextPage()
        let x = try #require(try storedUsers(context).first)
        try repo.delete(x)

        try await repo.loadNextPage()

        #expect(try storedUsers(context).isEmpty)
        let tombstones = try context.fetch(FetchDescriptor<DeletedUser>())
        #expect(tombstones.map(\.uuid) == ["x"])
    }

    @Test("sortOrder is incremental and stable across merges; the page cursor advances")
    func assignsStableIncrementalSortOrder() async throws {
        let api = MockAPIClient(pages: [
            [UserDTO.stub(uuid: "a"), UserDTO.stub(uuid: "b")],
            [UserDTO.stub(uuid: "c"), UserDTO.stub(uuid: "d")],
        ])
        let repo = UserRepository(apiClient: api, context: context, seed: "s")

        try await repo.loadNextPage()
        try await repo.loadNextPage()

        let users = try storedUsers(context)
        #expect(users.map(\.uuid) == ["a", "b", "c", "d"])
        #expect(users.map(\.sortOrder) == [0, 1, 2, 3])
        #expect(api.requests.map(\.page) == [1, 2])
    }

    @Test("New users append after a deletion without reordering the survivors")
    func newUsersAppendAfterDeletion() async throws {
        let api = MockAPIClient(pages: [
            [UserDTO.stub(uuid: "a"), UserDTO.stub(uuid: "b"), UserDTO.stub(uuid: "c")],
            [UserDTO.stub(uuid: "e")],
        ])
        let repo = UserRepository(apiClient: api, context: context, seed: "s")
        try await repo.loadNextPage()

        let b = try #require(try storedUsers(context).first { $0.uuid == "b" })
        try repo.delete(b)

        try await repo.loadNextPage()

        let users = try storedUsers(context)
        #expect(users.map(\.uuid) == ["a", "c", "e"])
        // "e" takes max(existing)+1 = 3; "a" and "c" keep their original order.
        #expect(try #require(users.last).sortOrder == 3)
    }
}
