//
//  APIClient.swift
//  RandomUser
//

import Foundation

/// Abstraction over the random-user network source. Behind a protocol so the
/// repository can be tested against a mock instead of the live API.
///
/// The requirement is `nonisolated`: the project defaults type isolation to
/// `@MainActor`, but fetching + decoding should run off the main actor, so callers
/// must not be pinned to it. `seed` makes pagination coherent within a session
/// (fewer incoming duplicates); it is the caller's responsibility, not the
/// persistence mechanism.
protocol APIClient: Sendable {
    nonisolated func fetchUsers(seed: String, page: Int, results: Int) async throws -> [UserDTO]
}

/// Errors surfaced by the API layer. `nonisolated` (like the DTOs) so it isn't tied
/// to the project's default main-actor isolation.
nonisolated enum APIError: Error {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed(underlying: Error)
}
