//
//  UserListViewModel.swift
//  RandomUser
//

import Foundation
import Observation

/// Drives the user list: owns the search term (debounced), the observable loading and
/// error state, and the command path (load more, delete) which it delegates to the
/// repository. Reads stay in the View via `@Query`; this filters those results.
@Observable
final class UserListViewModel {
    /// Bound to the search field. Each edit (re)starts the debounce timer.
    var searchText: String = "" {
        didSet { scheduleSearch() }
    }

    /// The debounced term that actually drives filtering — updated once the user stops
    /// typing for `debounce`.
    private(set) var searchTerm: String = ""

    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let repository: UserRepositoryProtocol
    private let debounce: Duration
    private var searchTask: Task<Void, Never>?

    init(repository: UserRepositoryProtocol, debounce: Duration = .milliseconds(300)) {
        self.repository = repository
        self.debounce = debounce
    }

    /// Loads the first page only when the store is empty. On relaunch the persisted
    /// users render straight from `@Query`, so no fetch is needed.
    func loadInitialIfNeeded(currentCount: Int) async {
        guard currentCount == 0 else { return }
        await loadMore()
    }

    /// Fetches and merges the next page. No-op while a load is already in flight, so the
    /// infinite-scroll trigger can fire freely without stacking requests.
    func loadMore() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await repository.loadNextPage()
        } catch {
            errorMessage = "Couldn't load users. Pull to retry."
        }
    }

    func delete(_ user: UserModel) {
        do {
            try repository.delete(user)
        } catch {
            errorMessage = "Couldn't delete user."
        }
    }

    /// In-memory filter the View applies to its `@Query` results, using the debounced
    /// term.
    func filtered(_ users: [UserModel]) -> [UserModel] {
        Self.filter(users, matching: searchTerm)
    }

    /// Pure matching logic (case-insensitive, partial, across name / surname / fullname / email),
    /// separated so it's testable without the debounce.
    static func filter(_ users: [UserModel], matching term: String) -> [UserModel] {
        let term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return users }
        return users.filter {
            $0.firstName.localizedCaseInsensitiveContains(term)
                || $0.lastName.localizedCaseInsensitiveContains(term)
                || $0.fullName.localizedCaseInsensitiveContains(term)
                || $0.email.localizedCaseInsensitiveContains(term)
        }
    }

    // MARK: - Debounce

    private func scheduleSearch() {
        searchTask?.cancel()
        let term = searchText
        searchTask = Task { [weak self, debounce] in
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled else { return }
            self?.searchTerm = term
        }
    }
}
