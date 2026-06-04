// Veda/Views/AuthorizationRequestView.swift
// Pantalla de solicitud de autorización de Screen Time.

import SwiftUI

struct AuthorizationRequestView: View {
    @EnvironmentObject var authVM: AuthorizationViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 72))
                .foregroundStyle(.blue)

            Text("Veda")
                .font(.largeTitle.bold())

            Text("Veda necesita acceso a Screen Time para bloquear apps según horarios personalizados.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            if let error = authVM.authError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: { authVM.requestAuthorization() }) {
                Label("Autorizar Screen Time", systemImage: "checkmark.shield")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)

            Text("Solo se usará en tu dispositivo personal. No se comparte ningún dato.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
    }
}
