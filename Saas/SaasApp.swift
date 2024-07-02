//
//  SaasApp.swift
//  Saas
//
//  Created by Simon Hajduk on 8/30/23.
//

import SwiftUI

@main
struct SaasApp: App {
    let persistenceController = PersistenceController.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }

}
