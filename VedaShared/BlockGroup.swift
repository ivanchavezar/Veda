// VedaShared/BlockGroup.swift
// Modelo de datos principal. Compartido entre la app y la extensión.

import Foundation
import FamilyControls

/// Días de la semana para repetición. Mapea a Calendar.weekday (1=domingo…7=sábado).
public struct WeekdaySet: Codable, Equatable {
    public var rawValue: Set<Int>

    public init(_ days: Set<Int> = Set(1...7)) {
        self.rawValue = days
    }

    public static let every = WeekdaySet(Set(1...7))

    /// Devuelve true si el día calendario dado está incluido.
    public func contains(_ weekday: Int) -> Bool {
        rawValue.contains(weekday)
    }
}

/// Un grupo de apps con una ventana horaria de DISPONIBILIDAD.
/// Las apps están DISPONIBLES entre availableStart y availableEnd;
/// fuera de ese rango están BLOQUEADAS.
public struct BlockGroup: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String

    /// Selección de apps (codificada como Data para persistencia).
    public var activitySelectionData: Data?

    /// Hora de inicio de DISPONIBILIDAD (segundos desde medianoche).
    public var availableStart: Int   // ej. 7*3600 = 07:00

    /// Hora de fin de DISPONIBILIDAD (segundos desde medianoche).
    public var availableEnd: Int     // ej. 15*3600 = 15:00

    /// Días en que aplica el horario.
    public var weekdays: WeekdaySet

    /// Modo estricto: impide editar o desactivar durante el bloqueo.
    public var strictMode: Bool

    /// Si el grupo está habilitado.
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        name: String = "",
        activitySelectionData: Data? = nil,
        availableStart: Int = 7 * 3600,
        availableEnd: Int = 23 * 3600,
        weekdays: WeekdaySet = .every,
        strictMode: Bool = false,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.activitySelectionData = activitySelectionData
        self.availableStart = availableStart
        self.availableEnd = availableEnd
        self.weekdays = weekdays
        self.strictMode = strictMode
        self.isEnabled = isEnabled
    }

    // MARK: - Computed helpers

    /// Devuelve la FamilyActivitySelection deserializada, si existe.
    public var activitySelection: FamilyActivitySelection? {
        guard let data = activitySelectionData else { return nil }
        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }

    /// Nombre de schedule para DeviceActivity. Usa el UUID para unicidad.
    public var deviceActivityName: String { "veda-\(id.uuidString)" }

    // MARK: - Estado actual

    /// Devuelve true si AHORA las apps deben estar bloqueadas.
    public func isCurrentlyBlocked() -> Bool {
        guard isEnabled else { return false }
        let now = Date()
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: now)
        guard weekdays.contains(weekday) else { return false }

        let secondsNow = cal.component(.hour, from: now) * 3600
                       + cal.component(.minute, from: now) * 60
                       + cal.component(.second, from: now)

        // Bloqueado = fuera de la ventana de disponibilidad
        return secondsNow < availableStart || secondsNow >= availableEnd
    }

    /// Cadena legible del horario de disponibilidad.
    public var scheduleDescription: String {
        "\(formatSeconds(availableStart)) – \(formatSeconds(availableEnd))"
    }

    private func formatSeconds(_ s: Int) -> String {
        let h = s / 3600
        let m = (s % 3600) / 60
        return String(format: "%02d:%02d", h, m)
    }
}

// MARK: - Persistencia

public extension BlockGroup {
    static func loadAll() -> [BlockGroup] {
        guard let data = AppGroup.defaults.data(forKey: AppGroup.blockGroupsKey),
              let groups = try? JSONDecoder().decode([BlockGroup].self, from: data)
        else { return [] }
        return groups
    }

    static func saveAll(_ groups: [BlockGroup]) {
        if let data = try? JSONEncoder().encode(groups) {
            AppGroup.defaults.set(data, forKey: AppGroup.blockGroupsKey)
        }
    }
}
