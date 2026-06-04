// Veda/Views/GroupRowView.swift
// Celda de la lista principal: nombre, horario y estado actual.

import SwiftUI

struct GroupRowView: View {
    let group: BlockGroup

    private var isBlocked: Bool { group.isCurrentlyBlocked() }

    var body: some View {
        HStack(spacing: 14) {
            // Indicador de estado
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
                .shadow(color: statusColor.opacity(0.5), radius: 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(group.name.isEmpty ? "Sin nombre" : group.name)
                        .font(.headline)

                    if group.strictMode {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    if !group.isEnabled {
                        Text("Desactivado")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("Disponible: \(group.scheduleDescription)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(weekdaysLabel)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Badge de estado
            Text(statusLabel)
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.15))
                .foregroundStyle(statusColor)
                .clipShape(Capsule())
        }
        .padding(.vertical, 6)
        .opacity(group.isEnabled ? 1.0 : 0.5)
    }

    // MARK: - Helpers

    private var statusColor: Color {
        guard group.isEnabled else { return .gray }
        return isBlocked ? .red : .green
    }

    private var statusLabel: String {
        guard group.isEnabled else { return "Inactivo" }
        return isBlocked ? "Bloqueado" : "Disponible"
    }

    private var weekdaysLabel: String {
        let names = ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"]
        let selected = group.weekdays.rawValue.sorted().map { names[$0 - 1] }
        if selected.count == 7 { return "Todos los días" }
        return selected.joined(separator: ", ")
    }
}
