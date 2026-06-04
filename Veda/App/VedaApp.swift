// Veda/App/VedaApp.swift
// Punto de entrada de la app.

import SwiftUI

@main
struct VedaApp: App {
    @StateObject private var authVM = AuthorizationViewModel()
    @StateObject private var groupsVM = BlockGroupsViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
                .environmentObject(groupsVM)
                .onAppear {
                    // Aplicar estado inicial según la hora actual
                    ScheduleManager.applyCurrentState(groups: groupsVM.groups)
                }
        }
    }
}
