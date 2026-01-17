//
//  ExpenseTrackerApp.swift
//  ExpenseTracker
//
//  Created by sanyk15 on 17.01.2026.
//

import SwiftUI
import CoreData

@main
struct ExpenseTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
