//
//  UserDTO+Stub.swift
//  RandomUserTests
//

import Foundation
@testable import RandomUser

extension UserDTO {
    /// Builds a DTO with sensible defaults; override only what a test cares about.
    static func stub(
        uuid: String,
        first: String = "First",
        last: String = "Last",
        email: String = "user@example.com",
        registered: Date = Date(timeIntervalSince1970: 0)
    ) -> UserDTO {
        UserDTO(
            gender: "female",
            name: .init(first: first, last: last),
            location: .init(
                street: .init(number: 1, name: "Main St"),
                city: "City",
                state: "State"
            ),
            email: email,
            login: .init(uuid: uuid),
            registered: .init(date: registered),
            phone: "000-000-000",
            picture: .init(large: "https://example.com/large.jpg",
                           thumbnail: "https://example.com/thumb.jpg")
        )
    }
}
