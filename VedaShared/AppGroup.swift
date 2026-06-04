// VedaShared/AppGroup.swift
// Constantes compartidas entre el app target y la extensión DeviceActivityMonitor.
// IMPORTANTE: Reemplaza "group.com.tuappleid.veda" con tu App Group ID real.

import Foundation

public enum AppGroup {
    /// Identificador del App Group. Debe coincidir exactamente con el valor
    /// registrado en el portal de Apple y en los entitlements de ambos targets.
    public static let identifier = "group.com.tuappleid.veda"

    /// UserDefaults compartido entre la app y la extensión.
    public static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier)!
    }

    /// Clave para almacenar/recuperar los grupos de bloqueo.
    public static let blockGroupsKey = "vedaBlockGroups"
}
