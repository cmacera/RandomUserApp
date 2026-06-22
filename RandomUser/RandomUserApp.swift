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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserModel.self,
            DeletedUser.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
