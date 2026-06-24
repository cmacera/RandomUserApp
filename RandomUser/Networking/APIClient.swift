//
//  APIClient.swift
//  RandomUser
//

import Foundation

/// Abstraction over the random-user network source, behind a protocol so the repository
/// can be tested against a mock. `seed` is chosen by the caller and makes the API's pages
/// deterministic (non-overlapping) within a session.
///
/// `@concurrent` keeps fetching + decoding off the MainActor (under the project's
/// approachable concurrency a plain `nonisolated async` would run on the caller). It sits
/// on the *requirement* because the repository calls through the protocol — that's what
/// governs the call site.
protocol APIClient: Sendable {
    @concurrent func fetchUsers(seed: String, page: Int, results: Int) async throws -> [UserDTO]
}

/// Errors surfaced by the API layer. `nonisolated` (like the DTOs) so it isn't tied
/// to the project's default main-actor isolation.
nonisolated enum APIError: Error {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed(underlying: Error)
}
