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
        // To enable iCloud sync, add the CloudKit capability in Xcode first,
        // then change .none to .private("iCloud.com.neha.ScubaLog")
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.neha.ScubaLog")
        )

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
