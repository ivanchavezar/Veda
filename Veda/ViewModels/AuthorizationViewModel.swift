// Veda/ViewModels/AuthorizationViewModel.swift
// Maneja la autorización de FamilyControls (.individual).

import SwiftUI
import FamilyControls

@MainActor
final class AuthorizationViewModel: ObservableObject {
    @Published var isAuthorized: Bool = false
    @Published var authError: String? = nil

    init() {
        // Verificar si ya está autorizado al iniciar
        checkAuthorizationStatus()
    }

    func requestAuthorization() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                isAuthorized = true
                authError = nil
            } catch {
                isAuthorized = false
                authError = "No se pudo obtener autorización de Screen Time: \(error.localizedDescription)"
            }
        }
    }

    private func checkAuthorizationStatus() {
        // En iOS 16+ podemos observar AuthorizationCenter.shared.authorizationStatus
        // para determinar si ya está autorizado.
        switch AuthorizationCenter.shared.authorizationStatus {
        case .approved:
            isAuthorized = true
        case .denied:
            isAuthorized = false
            authError = "El acceso a Screen Time fue denegado. Ve a Ajustes > Tiempo de Uso para habilitarlo."
        case .notDetermined:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }
}
