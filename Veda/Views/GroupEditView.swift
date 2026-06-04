// Veda/Views/GroupEditView.swift
// Formulario para crear/editar un BlockGroup.

import SwiftUI
import FamilyControls

struct GroupEditView: View {
    @EnvironmentObject var groupsVM: BlockGroupsViewModel
    @Environment(\.dismiss) private var dismiss

    // nil = crear nuevo; non-nil = editar existente
    let group: BlockGroup?

    // Estado del formulario
    @State private var name: String = ""
    @State private var activitySelection: FamilyActivitySelection = FamilyActivitySelection()
    @State private var availableStart: Date = Calendar.current.date(bySettingHour: 7,  minute: 0, second: 0, of: Date())!
    @State private var availableEnd:   Date = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date())!
    @State private var weekdays: WeekdaySet = .every
    @State private var strictMode: Bool = false
    @State private var isEnabled: Bool = true
    @State private var showingAppPicker = false
    @State private var validationError: String? = nil

    private var isEditing: Bool { group != nil }
    private let weekdayNames = ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"]

    init(group: BlockGroup?) {
        self.group = group
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Nombre
                Section("Nombre del grupo") {
                    TextField("Ej. Redes sociales", text: $name)
                }

                // MARK: Apps
                Section {
                    Button {
                        showingAppPicker = true
                    } label: {
                        HStack {
                            Label("Seleccionar apps", systemImage: "apps.iphone")
                            Spacer()
                            let count = activitySelection.applicationTokens.count
                                      + activitySelection.categoryTokens.count
                            if count > 0 {
                                Text("\(count) seleccionadas")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Apps a bloquear")
                } footer: {
                    Text("Las apps seleccionadas quedarán bloqueadas fuera de la ventana de disponibilidad.")
                }

                // MARK: Horario
                Section {
                    DatePicker("Inicio disponibilidad", selection: $availableStart,
                               displayedComponents: .hourAndMinute)
                    DatePicker("Fin disponibilidad", selection: $availableEnd,
                               displayedComponents: .hourAndMinute)
                } header: {
                    Text("Ventana de disponibilidad")
                } footer: {
                    Text("Las apps estarán disponibles entre estos horarios. Fuera de ellos quedan bloqueadas.")
                }

                // MARK: Días
                Section("Días de la semana") {
                    HStack(spacing: 8) {
                        ForEach(1...7, id: \.self) { day in
                            let isSelected = weekdays.contains(day)
                            Button {
                                toggleDay(day)
                            } label: {
                                Text(weekdayNames[day - 1])
                                    .font(.caption.bold())
                                    .frame(width: 38, height: 38)
                                    .background(isSelected ? Color.blue : Color.secondary.opacity(0.15))
                                    .foregroundStyle(isSelected ? .white : .primary)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // MARK: Opciones
                Section("Opciones") {
                    Toggle("Habilitado", isOn: $isEnabled)

                    Toggle(isOn: $strictMode) {
                        VStack(alignment: .leading, spacing: 2) {
                            Label("Modo estricto", systemImage: "lock.shield")
                            Text("Impide editar o desactivar durante el bloqueo.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: Error de validación
                if let error = validationError {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isEditing ? "Editar grupo" : "Nuevo grupo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .bold()
                }
            }
            .familyActivityPicker(isPresented: $showingAppPicker,
                                  selection: $activitySelection)
            .onAppear { loadExistingGroup() }
        }
    }

    // MARK: - Helpers

    private func toggleDay(_ day: Int) {
        var days = weekdays.rawValue
        if days.contains(day) {
            // Impedir dejar sin días seleccionados
            if days.count > 1 { days.remove(day) }
        } else {
            days.insert(day)
        }
        weekdays = WeekdaySet(days)
    }

    private func loadExistingGroup() {
        guard let g = group else { return }
        name = g.name
        if let sel = g.activitySelection { activitySelection = sel }
        availableStart = secondsToDate(g.availableStart)
        availableEnd   = secondsToDate(g.availableEnd)
        weekdays       = g.weekdays
        strictMode     = g.strictMode
        isEnabled      = g.isEnabled
    }

    private func save() {
        // Validar
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationError = "El nombre no puede estar vacío."
            return
        }
        let startSec = dateToSeconds(availableStart)
        let endSec   = dateToSeconds(availableEnd)
        guard endSec > startSec else {
            validationError = "La hora de fin debe ser posterior a la de inicio."
            return
        }
        guard !activitySelection.applicationTokens.isEmpty
              || !activitySelection.categoryTokens.isEmpty else {
            validationError = "Selecciona al menos una app o categoría."
            return
        }

        let selectionData = try? JSONEncoder().encode(activitySelection)

        var updated = group ?? BlockGroup()
        updated.name                 = name.trimmingCharacters(in: .whitespaces)
        updated.activitySelectionData = selectionData
        updated.availableStart       = startSec
        updated.availableEnd         = endSec
        updated.weekdays             = weekdays
        updated.strictMode           = strictMode
        updated.isEnabled            = isEnabled

        if isEditing {
            groupsVM.update(updated)
        } else {
            groupsVM.add(updated)
        }
        dismiss()
    }

    // MARK: - Conversión hora ↔ segundos

    private func dateToSeconds(_ date: Date) -> Int {
        let cal = Calendar.current
        return cal.component(.hour, from: date) * 3600
             + cal.component(.minute, from: date) * 60
    }

    private func secondsToDate(_ seconds: Int) -> Date {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        return Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: Date()) ?? Date()
    }
}
