//
//  GitGudApp.swift
//  GitGud
//
//  Created by somil jain on 13/07/26.
//

import SwiftUI

@main
struct GitGudApp: App {
    @StateObject private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        if session.isLoggedIn {
            ContentView()
        } else {
            LoginView()
        }
    }
}
