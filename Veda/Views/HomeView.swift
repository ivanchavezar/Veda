// Veda/Views/HomeView.swift
// Pantalla principal: lista de grupos con estado actual.

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var groupsVM: BlockGroupsViewModel
    @State private var showingAddGroup = false
    @State private var editingGroup: BlockGroup? = nil

    var body: some View {
        NavigationStack {
            Group {
                if groupsVM.groups.isEmpty {
                    emptyState
                } else {
                    groupList
                }
            }
            .navigationTitle("Veda")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddGroup = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddGroup) {
                GroupEditView(group: nil)
                    .environmentObject(groupsVM)
            }
            .sheet(item: $editingGroup) { group in
                GroupEditView(group: group)
                    .environmentObject(groupsVM)
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundStyle(.blue.opacity(0.7))
            Text("Sin grupos de bloqueo")
                .font(.title2.bold())
            Text("Toca + para crear tu primer grupo de horario.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var groupList: some View {
        List {
            ForEach(groupsVM.groups) { group in
                GroupRowView(group: group)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if groupsVM.isEditingLocked(for: group) {
                            // Modo estricto activo: no abrir editor
                        } else {
                            editingGroup = group
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            groupsVM.delete(group)
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                        .disabled(groupsVM.isEditingLocked(for: group))

                        Button {
                            groupsVM.toggleEnabled(group)
                        } label: {
                            Label(
                                group.isEnabled ? "Desactivar" : "Activar",
                                systemImage: group.isEnabled ? "pause.fill" : "play.fill"
                            )
                        }
                        .tint(group.isEnabled ? .orange : .green)
                        .disabled(groupsVM.isEditingLocked(for: group))
                    }
            }
        }
        .listStyle(.insetGrouped)
    }
}
