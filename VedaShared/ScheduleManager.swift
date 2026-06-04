// VedaShared/ScheduleManager.swift
// Gestión de DeviceActivitySchedule y ManagedSettingsStore.
// Esta lógica es utilizada tanto por la app (para registrar schedules)
// como por la extensión (para aplicar/quitar shields).

import Foundation
import DeviceActivity
import ManagedSettings
import FamilyControls

public final class ScheduleManager {

    // MARK: - ManagedSettingsStore

    /// Identificador del store. Debe ser el mismo en app y extensión.
    /// Usar el App Group ID como prefijo garantiza unicidad.
    public static func store(for groupID: UUID) -> ManagedSettingsStore {
        ManagedSettingsStore(named: ManagedSettingsStore.Name("veda-\(groupID.uuidString)"))
    }

    // MARK: - Aplicar / quitar shield

    /// Aplica el shield y, opcionalmente, suprime las notificaciones del grupo (bloqueado).
    public static func applyShield(for group: BlockGroup) {
        guard let selection = group.activitySelection else { return }
        let store = Self.store(for: group.id)

        // Shield visual: muestra la pantalla de "app no disponible"
        store.shield.applications = selection.applicationTokens.isEmpty
            ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)

        // Supresión de notificaciones durante el bloqueo
        if group.suppressNotifications {
            applyNotificationSuppression(store: store, selection: selection)
        }
    }

    /// Limpia el shield y restaura las notificaciones del grupo (disponible).
    public static func clearShield(for group: BlockGroup) {
        let store = Self.store(for: group.id)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        // Restaurar notificaciones al salir del período de bloqueo
        store.notifications.badgingEnabled = nil
        if #available(iOS 16.0, *) {
            store.notifications.notificationsEnabled = nil
        }
    }

    // MARK: - Supresión de notificaciones

    /// Aplica restricciones de notificación usando ManagedSettings.
    ///
    /// ManagedSettings provee dos niveles de control sobre notificaciones:
    ///
    /// 1. `notificationsEnabled = false` (iOS 16+):
    ///    Desactiva completamente las notificaciones (banners, sonidos, badges)
    ///    para las apps cubiertos por el store. Es el método más efectivo.
    ///
    /// 2. `badgingEnabled = false`:
    ///    Oculta el badge numérico del icono. Funciona en todos los iOS soportados.
    ///
    /// NOTA: `notificationsEnabled` aplica a nivel del ManagedSettingsStore completo,
    /// no solo a las apps del set. Si necesitas granularidad por app, la alternativa
    /// es crear un store distinto por app. Esta implementación usa un store por
    /// BlockGroup, lo que ya da el alcance correcto.
    private static func applyNotificationSuppression(
        store: ManagedSettingsStore,
        selection: FamilyActivitySelection
    ) {
        // Ocultar badges en todos los casos
        store.notifications.badgingEnabled = false

        // iOS 16+: desactivar notificaciones completamente (banners + sonidos)
        if #available(iOS 16.0, *) {
            store.notifications.notificationsEnabled = false
        }
    }

    // MARK: - Registrar schedules

    /// Registra (o vuelve a registrar) los schedules para todos los grupos habilitados.
    /// Debe llamarse desde el app target cada vez que cambie la configuración.
    public static func syncSchedules(groups: [BlockGroup]) {
        let center = DeviceActivityCenter()

        // Cancelar todos los schedules anteriores de Veda
        // (no hay API para listarlos; cancelamos por nombre)
        for group in groups {
            let name = DeviceActivityName(group.deviceActivityName)
            center.stopMonitoring([name])
        }

        for group in groups {
            guard group.isEnabled, group.activitySelection != nil else { continue }
            scheduleGroup(group, center: center)
        }
    }

    /// Registra dos schedules complementarios para un grupo:
    ///   • "availability": cubre la ventana disponible → al terminar (intervalDidEnd) bloqueamos.
    ///   • No se necesita un segundo schedule porque DeviceActivityMonitor
    ///     recibe intervalDidStart/intervalDidEnd de cada schedule.
    ///
    /// Estrategia de bloqueo INVERTIDO:
    ///   El schedule cubre la ventana de DISPONIBILIDAD.
    ///   - intervalDidStart → limpiar shield (apps disponibles).
    ///   - intervalDidEnd   → aplicar shield (apps bloqueadas).
    ///   Al arrancar la app se evalúa el estado inicial manualmente.
    public static func scheduleGroup(_ group: BlockGroup, center: DeviceActivityCenter = DeviceActivityCenter()) {
        guard group.isEnabled else { return }

        let startHour = group.availableStart / 3600
        let startMin  = (group.availableStart % 3600) / 60
        let endHour   = group.availableEnd / 3600
        let endMin    = (group.availableEnd % 3600) / 60

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: startHour, minute: startMin),
            intervalEnd:   DateComponents(hour: endHour,   minute: endMin),
            repeats: true,
            warningTime: nil
        )

        let name = DeviceActivityName(group.deviceActivityName)
        do {
            try center.startMonitoring(name, during: schedule)
        } catch {
            print("[ScheduleManager] Error al registrar schedule \(group.name): \(error)")
        }
    }

    // MARK: - Estado inicial

    /// Aplica el estado de bloqueo correcto a todos los grupos basándose en la hora actual.
    /// Llamar al arrancar la app y después de editar grupos.
    public static func applyCurrentState(groups: [BlockGroup]) {
        for group in groups {
            if group.isCurrentlyBlocked() {
                applyShield(for: group)
            } else {
                clearShield(for: group)
            }
        }
    }
}
