//
//  UserDTO.swift
//  RandomUser
//

import Foundation

/// Top-level decode target for `GET /api/`. Only `results` is decoded; `info`
/// (seed/page/version) is ignored.
///
/// All DTOs are `nonisolated`: the project defaults type isolation to `@MainActor`,
/// but decoding must be usable off the main actor (the `APIClient` decodes in the
/// background), so the `Decodable` conformance can't be main-actor isolated.
nonisolated struct UsersResponseDTO: Decodable {
    let results: [UserDTO]
}

/// `Decodable` mirror of a single API user — kept separate from `UserModel` so the
/// API shape never leaks into the persistence schema. It declares *only* the fields
/// the app renders; everything else in the payload (login secrets, id, postcode,
/// coordinates, dob, nat, cell…) is simply not decoded, which also sidesteps the
/// API's mixed-type quirks (`postcode` is Int|String, `id.value` is nullable).
nonisolated struct UserDTO: Decodable {
    let gender: String
    let name: Name
    let location: Location
    let email: String
    let login: Login
    let registered: Registered
    let phone: String
    let picture: Picture

    nonisolated struct Name: Decodable {
        let first: String
        let last: String
    }

    nonisolated struct Location: Decodable {
        let street: Street
        let city: String
        let state: String

        /// Live API: `street` is an object `{ number, name }`, not a string.
        nonisolated struct Street: Decodable {
            let number: Int
            let name: String
        }
    }

    nonisolated struct Login: Decodable {
        let uuid: String
    }

    /// Live API: `registered` is an object `{ date, age }` with an ISO8601 date.
    nonisolated struct Registered: Decodable {
        let date: Date
    }

    nonisolated struct Picture: Decodable {
        let large: String
        let thumbnail: String
    }
}

extension UserDTO {
    /// Maps the DTO to a persistable model. `sortOrder` is the repository's
    /// responsibility (assigned once at first insert), so it's injected here.
    ///
    /// `@MainActor` because it constructs a `UserModel` (a `@Model`, which the project
    /// isolates to the main actor) — the merge that calls this runs on the main context.
    @MainActor
    func toModel(sortOrder: Int) -> UserModel {
        UserModel(
            uuid: login.uuid,
            sortOrder: sortOrder,
            firstName: name.first,
            lastName: name.last,
            email: email,
            phone: phone,
            gender: gender,
            street: "\(location.street.number) \(location.street.name)"
                .trimmingCharacters(in: .whitespaces),
            city: location.city,
            state: location.state,
            registered: registered.date,
            thumbnailURL: picture.thumbnail,
            pictureURL: picture.large
        )
    }
}
