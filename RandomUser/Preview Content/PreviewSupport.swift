//
//  PreviewSupport.swift
//  RandomUser
//

#if DEBUG
import Foundation
import SwiftData

extension UserModel {
    /// A ready-made user for previews. Defaults to a real randomuser.me portrait so
    /// previews show an image; override only what a preview cares about.
    static func sample(
        uuid: String = UUID().uuidString,
        first: String = "Ada",
        last: String = "Lovelace",
        email: String = "ada.lovelace@example.com",
        gender: String = "women",
        portrait: Int = 12
    ) -> UserModel {
        UserModel(
            uuid: uuid,
            sortOrder: 0,
            firstName: first,
            lastName: last,
            email: email,
            phone: "600 123 456",
            gender: gender == "women" ? "female" : "male",
            street: "12 Baker Street",
            city: "London",
            state: "England",
            registered: Date(timeIntervalSince1970: 1_300_000_000),
            thumbnailURL: "https://randomuser.me/api/portraits/thumb/\(gender)/\(portrait).jpg",
            pictureURL: "https://randomuser.me/api/portraits/\(gender)/\(portrait).jpg"
        )
    }
}

extension Array where Element == UserModel {
    /// A few distinct users for list previews.
    static var samplePeople: [UserModel] {
        [
            .sample(uuid: "0", first: "Ada", last: "Lovelace", email: "ada@example.com", gender: "women", portrait: 12),
            .sample(uuid: "1", first: "Alan", last: "Turing", email: "alan@example.com", gender: "men", portrait: 33),
            .sample(uuid: "2", first: "Grace", last: "Hopper", email: "grace@example.com", gender: "women", portrait: 45),
        ]
    }
}

/// In-memory container seeded with the given users (`samplePeople` by default; pass
/// `[]` for the empty-state preview). `sortOrder` follows array order.
func previewContainer(_ users: [UserModel] = .samplePeople) -> ModelContainer {
    let container = try! ModelContainer(
        for: UserModel.self, DeletedUser.self, PaginationState.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    for (index, user) in users.enumerated() {
        user.sortOrder = index
        container.mainContext.insert(user)
    }
    return container
}

/// `APIClient` stub for previews — returns nothing, so previews never hit the network
/// and the list shows only its seeded users.
nonisolated struct PreviewAPIClient: APIClient {
    func fetchUsers(seed: String, page: Int, results: Int) async throws -> [UserDTO] { [] }
}

/// A real repository wired to a preview container + the no-network client, so delete
/// works in previews while pagination stays offline.
func previewRepository(_ container: ModelContainer) -> UserRepository {
    UserRepository(apiClient: PreviewAPIClient(), context: container.mainContext)
}
#endif
