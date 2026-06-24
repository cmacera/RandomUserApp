//
//  UserListViewModelTests.swift
//  RandomUserTests
//

import Foundation
import Testing
@testable import RandomUser

struct UserListViewModelTests {

    private func user(uuid: String, first: String, last: String, email: String) -> UserModel {
        UserDTO.stub(uuid: uuid, first: first, last: last, email: email).toModel(sortOrder: 0)
    }

    private func sampleUsers() -> [UserModel] {
        [
            user(uuid: "1", first: "Alice", last: "Smith", email: "alice@example.com"),
            user(uuid: "2", first: "Bob", last: "Jones", email: "bob@work.com"),
            user(uuid: "3", first: "Carol", last: "Smithson", email: "carol@example.com"),
        ]
    }

    // MARK: - Filter

    @Test("Empty term returns every user")
    func filterEmptyReturnsAll() {
        let all = sampleUsers()
        #expect(UserListViewModel.filter(all, matching: "   ").count == 3)
    }

    @Test("Matches surname, case-insensitive and partial")
    func filterMatchesSurname() {
        let matches = UserListViewModel.filter(sampleUsers(), matching: "smith")
        #expect(Set(matches.map(\.uuid)) == ["1", "3"])  // Smith + Smithson
    }

    @Test("Matches first name and email too")
    func filterMatchesNameAndEmail() {
        let users = sampleUsers()
        #expect(UserListViewModel.filter(users, matching: "ALICE").map(\.uuid) == ["1"])
        #expect(UserListViewModel.filter(users, matching: "work.com").map(\.uuid) == ["2"])
    }

    @Test("Matches the full name as a contiguous term across first and last")
    func filterMatchesFullName() {
        let users = sampleUsers()
        #expect(UserListViewModel.filter(users, matching: "Alice Smith").map(\.uuid) == ["1"])
        #expect(UserListViewModel.filter(users, matching: "alice sm").map(\.uuid) == ["1"])  // crosses into surname
    }

    // MARK: - Debounce

    @Test("Search term is debounced: not applied immediately, last value wins")
    func debounceDelaysAndCoalesces() async throws {
        let vm = UserListViewModel(repository: MockUserRepository(), debounce: .milliseconds(50))

        vm.searchText = "a"
        vm.searchText = "ab"
        #expect(vm.searchTerm == "")  // nothing applied synchronously

        try await Task.sleep(for: .milliseconds(200))
        #expect(vm.searchTerm == "ab")  // only the final value lands
    }

    // MARK: - Commands

    @Test("Initial load fetches only when the store is empty")
    func loadsInitialOnlyWhenEmpty() async {
        let repo = MockUserRepository()
        let vm = UserListViewModel(repository: repo)

        await vm.loadInitialIfNeeded(currentCount: 5)
        #expect(repo.loadNextPageCallCount == 0)

        await vm.loadInitialIfNeeded(currentCount: 0)
        #expect(repo.loadNextPageCallCount == 1)
    }

    @Test("delete delegates to the repository")
    func deleteDelegates() {
        let repo = MockUserRepository()
        let vm = UserListViewModel(repository: repo)
        let target = user(uuid: "1", first: "Alice", last: "Smith", email: "alice@example.com")

        vm.delete(target)

        #expect(repo.deletedUsers.map(\.uuid) == ["1"])
    }

    @Test("A failed load surfaces an error message")
    func loadMoreSetsErrorOnFailure() async {
        let repo = MockUserRepository()
        repo.loadError = APIError.httpStatus(500)
        let vm = UserListViewModel(repository: repo)

        await vm.loadMore()

        #expect(vm.errorMessage != nil)
        #expect(vm.isLoading == false)
    }
}
