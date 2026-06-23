//
//  RandomUserApp.swift
//  RandomUser
//
//  Created by Carlos Martín on 22/06/2026.
//

import SwiftUI
import SwiftData

@main
struct RandomUserApp: App {
    private let sharedModelContainer: ModelContainer
    private let repository: UserRepository

    init() {
        let schema = Schema([
            UserModel.self,
            DeletedUser.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        sharedModelContainer = container
        repository = UserRepository(
            apiClient: RandomUserAPIClient(),
            context: container.mainContext
        )
    }

    var body: some Scene {
        WindowGroup {
            UserListView(repository: repository)
        }
        .modelContainer(sharedModelContainer)
    }
}
