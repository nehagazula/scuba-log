//
//  Scuba_LogApp.swift
//  Scuba Log
//
//  Created by Neha Peace on 4/7/24.
//

import SwiftUI
import SwiftData

@main
struct Scuba_LogApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Entry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false) //false

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
