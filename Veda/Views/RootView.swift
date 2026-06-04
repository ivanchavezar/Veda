// Veda/Views/RootView.swift
// Vista raíz: solicita autorización si no está concedida; muestra HomeView si lo está.

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authVM: AuthorizationViewModel

    var body: some View {
        Group {
            if authVM.isAuthorized {
                HomeView()
            } else {
                AuthorizationRequestView()
            }
        }
    }
}
