//
//  UserRepositoryProtocol.swift
//  RandomUser
//

/// The write path the view model drives: load more, delete. Reads stay in the View
/// via `@Query`. Behind a protocol so the view model can be exercised with a mock in
/// tests and SwiftUI previews without a live store.
protocol UserRepositoryProtocol {
    /// True while a page load is in flight (drives the list's loading indicator and
    /// guards the infinite-scroll trigger).
    var isLoading: Bool { get }

    /// Fetches the next page and merges it into the store.
    func loadNextPage() async throws

    /// Removes a user and writes a tombstone so a later fetch can't bring it back.
    func delete(_ user: UserModel) throws
}
