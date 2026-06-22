//
//  DeletedUser.swift
//  RandomUser
//

import Foundation
import SwiftData

/// Tombstone for a deleted user. Kept in its own table (rather than an `isDeleted`
/// flag on `UserModel`) so it survives the server: on every merge the repository
/// filters incoming users against these uuids *before* inserting, guaranteeing a
/// deleted user never reappears even if a later API response includes it.
@Model
final class DeletedUser {
    @Attribute(.unique) var uuid: String
    var deletedAt: Date

    init(uuid: String, deletedAt: Date) {
        self.uuid = uuid
        self.deletedAt = deletedAt
    }
}
