//
//  NewVisitView.swift
//  trackmyrvu
//
//  Created by Claude on 2026-02-06.
//

import SwiftUI

struct NewVisitView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EntryViewModel
    @State private var showAddProcedure = false

    init(visit: Visit? = nil) {
        _viewModel = State(initialValue: EntryViewModel(visit: visit))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Date and Time Section
                Section("Visit Details") {
                    DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)

                    Toggle("Include Time", isOn: Binding(
                        get: { viewModel.time != nil },
                        set: { include in
                            viewModel.time = include ? Date() : nil
                        }
                    ))

                    if viewModel.time != nil {
                        DatePicker("Time", selection: Binding(
                            get: { viewModel.time ?? Date() },
                            set: { viewModel.time = $0 }
                        ), displayedComponents: .hourAndMinute)
                    }

                    Toggle("No Show", isOn: $viewModel.isNoShow)
                        .tint(.orange)
                }

                // Notes Section
                Section("Notes") {
                    TextField("Optional notes...", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Favorites Section
                if !viewModel.isNoShow {
                    Section {
                        FavoritesView { code in
                            viewModel.addProcedure(
                                hcpcs: code.hcpcs,
                                description: code.description,
                                statusCode: code.statusCode,
                                workRVU: code.workRVU
                            )
                        }
                    } header: {
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                            Text("Quick Add from Favorites")
                        }
                    }
                }

                // Procedures Section
                Section {
                    if viewModel.procedures.isEmpty {
                        if !viewModel.isNoShow {
                            Text("No procedures added")
                                .foregroundStyle(.secondary)
                                .italic()
                        } else {
                            Text("No-show visit (procedures not required)")
                                .foregroundStyle(.secondary)
                                .italic()
                        }
                    } else {
                        ForEach(Array(viewModel.procedures.enumerated()), id: \.element.id) { index, procedure in
                            ProcedureRow(
                                procedure: procedure,
                                onQuantityChange: { newQuantity in
                                    viewModel.updateQuantity(at: index, quantity: newQuantity)
                                },
                                onDelete: {
                                    viewModel.removeProcedure(at: index)
                                }
                            )
                        }
                    }

                    Button {
                        showAddProcedure = true
                    } label: {
                        Label("Add Procedure", systemImage: "plus.circle.fill")
                    }
                } header: {
                    HStack {
                        Text("Procedures")
                        Spacer()
                        if !viewModel.procedures.isEmpty {
                            Text("Total: \(String(format: "%.2f", viewModel.totalWorkRVU)) RVU")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }

                // Error Display
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(viewModel.isEditMode ? "Edit Visit" : "New Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.isEditMode ? "Update" : "Save") {
                        Task {
                            let success = await viewModel.submitVisit()
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isSubmitting)
                }
            }
            .sheet(isPresented: $showAddProcedure) {
                RVUSearchView { hcpcs, description, statusCode, workRVU in
                    viewModel.addProcedure(
                        hcpcs: hcpcs,
                        description: description,
                        statusCode: statusCode,
                        workRVU: workRVU
                    )
                }
            }
            .alert("Visit Created", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your visit has been saved successfully.")
            }
        }
    }
}

// MARK: - Procedure Row

struct ProcedureRow: View {
    let procedure: ProcedureEntry
    let onQuantityChange: (Int) -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(procedure.hcpcs)
                        .font(.headline)
                    Text(procedure.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.2f", procedure.workRVU))
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                    Text("×\(procedure.quantity)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Text("Quantity:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Stepper("\(procedure.quantity)", value: Binding(
                    get: { procedure.quantity },
                    set: { onQuantityChange($0) }
                ), in: 1...99)
                .labelsHidden()

                Spacer()

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NewVisitView()
}
