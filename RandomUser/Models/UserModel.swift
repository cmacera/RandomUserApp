//
//  UserModel.swift
//  RandomUser
//

import Foundation
import SwiftData

/// Persisted user. Identity is `login.uuid` (`@Attribute(.unique)`), which gives
/// upsert-on-conflict for free and fails on the safe side vs. email collisions.
///
/// `sortOrder` is assigned once at first insert and never mutated on upsert, so the
/// list keeps a stable order (SwiftData does not guarantee fetch order otherwise).
///
/// Only the fields the UI actually renders are stored (list: name/email/phone/picture;
/// detail: gender/location/registered). The full API payload is richer — we map just
/// what's needed. This is intentionally NOT `Codable`: decode a separate `UserDTO`
/// and map it, keeping the persistence schema decoupled from the API shape.
@Model
final class UserModel {
    @Attribute(.unique) var uuid: String
    var sortOrder: Int

    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    var gender: String

    // Location (detail view)
    var street: String
    var city: String
    var state: String

    var registered: Date

    // Picture URLs: thumbnail for the list cell, large for the detail view.
    var thumbnailURL: String
    var pictureURL: String

    init(
        uuid: String,
        sortOrder: Int,
        firstName: String,
        lastName: String,
        email: String,
        phone: String,
        gender: String,
        street: String,
        city: String,
        state: String,
        registered: Date,
        thumbnailURL: String,
        pictureURL: String
    ) {
        self.uuid = uuid
        self.sortOrder = sortOrder
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.gender = gender
        self.street = street
        self.city = city
        self.state = state
        self.registered = registered
        self.thumbnailURL = thumbnailURL
        self.pictureURL = pictureURL
    }
}

extension UserModel {
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
