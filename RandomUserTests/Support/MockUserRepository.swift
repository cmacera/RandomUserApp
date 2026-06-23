//
//  MockUserRepository.swift
//  RandomUserTests
//

import Foundation
@testable import RandomUser

/// Test double for `UserRepositoryProtocol`. Records calls and can be configured to
/// throw, so the view model can be exercised without a live store.
final class MockUserRepository: UserRepositoryProtocol {
    private(set) var loadNextPageCallCount = 0
    private(set) var deletedUsers: [UserModel] = []

    var loadError: Error?
    var deleteError: Error?

    func loadNextPage() async throws {
        loadNextPageCallCount += 1
        if let loadError { throw loadError }
    }

    func delete(_ user: UserModel) throws {
        if let deleteError { throw deleteError }
        deletedUsers.append(user)
    }
}
