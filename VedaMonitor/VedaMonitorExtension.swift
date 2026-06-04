// VedaMonitor/VedaMonitorExtension.swift
// DeviceActivityMonitor Extension.
// Este target se ejecuta en segundo plano cuando el sistema dispara
// los eventos de inicio/fin del schedule registrado.
//
// IMPORTANTE: Este archivo pertenece al target VedaMonitor (extensión),
// NO al target principal de la app.

import DeviceActivity
import ManagedSettings
import Foundation

// El nombre de la clase debe coincidir con el NSExtensionPrincipalClass
// declarado en el Info.plist de la extensión.
@objc(VedaMonitorExtension)
class VedaMonitorExtension: DeviceActivityMonitor {

    // MARK: - Ventana de disponibilidad EMPIEZA → limpiar shield

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // Recuperar los grupos guardados desde el App Group compartido
        let groups = BlockGroup.loadAll()

        // Buscar el grupo que corresponde a este schedule
        guard let group = groups.first(where: { $0.deviceActivityName == activity.rawValue }) else {
            return
        }

        // La ventana de disponibilidad comenzó → quitar el shield
        ScheduleManager.clearShield(for: group)
    }

    // MARK: - Ventana de disponibilidad TERMINA → aplicar shield

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        let groups = BlockGroup.loadAll()
        guard let group = groups.first(where: { $0.deviceActivityName == activity.rawValue }) else {
            return
        }

        // La ventana de disponibilidad terminó → aplicar el shield
        ScheduleManager.applyShield(for: group)
    }

    // MARK: - Warning (5 min antes del fin, si warningTime fue configurado)

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name,
                                         activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        // No se usa en esta implementación, pero puede personalizarse.
    }
}
