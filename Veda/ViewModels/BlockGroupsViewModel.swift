// Veda/ViewModels/BlockGroupsViewModel.swift
// Gestión CRUD de BlockGroups y sincronización de schedules.

import SwiftUI
import FamilyControls
import DeviceActivity

@MainActor
final class BlockGroupsViewModel: ObservableObject {
    @Published var groups: [BlockGroup] = []

    init() {
        groups = BlockGroup.loadAll()
    }

    // MARK: - CRUD

    func add(_ group: BlockGroup) {
        groups.append(group)
        persist()
    }

    func update(_ group: BlockGroup) {
        guard let idx = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[idx] = group
        persist()
    }

    func delete(_ group: BlockGroup) {
        // Limpiar shield y detener schedule antes de eliminar
        ScheduleManager.clearShield(for: group)
        let center = DeviceActivityCenter()
        center.stopMonitoring([DeviceActivityName(group.deviceActivityName)])
        groups.removeAll { $0.id == group.id }
        persist()
    }

    func toggleEnabled(_ group: BlockGroup) {
        guard let idx = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[idx].isEnabled.toggle()
        persist()
    }

    // MARK: - Modo estricto

    /// Devuelve true si el grupo está en modo estricto Y actualmente bloqueado,
    /// lo que impide edición.
    func isEditingLocked(for group: BlockGroup) -> Bool {
        group.strictMode && group.isCurrentlyBlocked()
    }

    // MARK: - Persistencia y sincronización

    private func persist() {
        BlockGroup.saveAll(groups)
        ScheduleManager.syncSchedules(groups: groups)
        ScheduleManager.applyCurrentState(groups: groups)
    }
}
