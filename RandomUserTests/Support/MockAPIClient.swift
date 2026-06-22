//
//  MockAPIClient.swift
//  RandomUserTests
//

import Foundation
@testable import RandomUser

/// Test double for `APIClient`. Returns queued pages of DTOs (one per call) or throws
/// a configured error, and records every request for assertions.
///
/// `nonisolated` + `@unchecked Sendable` with an `NSLock`: it satisfies the
/// `nonisolated` protocol requirement and stays safe to call from any context, while
/// keeping `requests` synchronously readable from tests (no `await` needed).
nonisolated final class MockAPIClient: APIClient, @unchecked Sendable {
    struct Request: Equatable, Sendable {
        let seed: String
        let page: Int
        let results: Int
    }

    private let lock = NSLock()
    private var queuedPages: [[UserDTO]]
    private var error: Error?
    private var _requests: [Request] = []

    init(pages: [[UserDTO]] = [], error: Error? = nil) {
        self.queuedPages = pages
        self.error = error
    }

    var requests: [Request] {
        lock.withLock { _requests }
    }

    func fetchUsers(seed: String, page: Int, results: Int) async throws -> [UserDTO] {
        try lock.withLock {
            _requests.append(Request(seed: seed, page: page, results: results))
            if let error { throw error }
            return queuedPages.isEmpty ? [] : queuedPages.removeFirst()
        }
    }
}
