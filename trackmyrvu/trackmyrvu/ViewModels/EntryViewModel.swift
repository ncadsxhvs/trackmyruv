//
//  EntryViewModel.swift
//  trackmyrvu
//
//  Created by Claude on 2026-02-06.
//

import Foundation

/// ViewModel for creating or editing visit entries
@Observable
@MainActor
class EntryViewModel {
    // Visit details
    var date = Date()
    var time: Date?
    var notes = ""
    var isNoShow = false

    // Procedures
    var procedures: [ProcedureEntry] = []

    // UI state
    var isSubmitting = false
    var errorMessage: String?
    var showSuccessAlert = false

    // Edit mode
    var editingVisitId: String?
    var isEditMode: Bool { editingVisitId != nil }

    private let apiService = APIService.shared

    /// Initialize with an existing visit for editing
    init(visit: Visit? = nil) {
        if let visit = visit {
            self.editingVisitId = visit.id

            // Parse date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            self.date = dateFormatter.date(from: visit.date) ?? Date()

            // Parse time if present
            if let timeString = visit.time, !timeString.isEmpty {
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm:ss"
                if let timeComponents = timeFormatter.date(from: timeString) {
                    // Combine date and time
                    let calendar = Calendar.current
                    let timeComps = calendar.dateComponents([.hour, .minute, .second], from: timeComponents)
                    self.time = calendar.date(bySettingHour: timeComps.hour ?? 0,
                                               minute: timeComps.minute ?? 0,
                                               second: 0,
                                               of: Date())
                }
            }

            self.notes = visit.notes ?? ""
            self.isNoShow = visit.isNoShow

            // Convert procedures
            self.procedures = visit.procedures.map { proc in
                ProcedureEntry(
                    id: UUID(),
                    hcpcs: proc.hcpcs,
                    description: proc.description,
                    statusCode: proc.statusCode,
                    workRVU: proc.workRVU,
                    quantity: proc.quantity
                )
            }
        }
    }

    func addProcedure(hcpcs: String, description: String, statusCode: String, workRVU: Double) {
        let procedure = ProcedureEntry(
            id: UUID(),
            hcpcs: hcpcs,
            description: description,
            statusCode: statusCode,
            workRVU: workRVU,
            quantity: 1
        )
        procedures.append(procedure)
    }

    func removeProcedure(at index: Int) {
        guard index < procedures.count else { return }
        procedures.remove(at: index)
    }

    func updateQuantity(at index: Int, quantity: Int) {
        guard index < procedures.count else { return }
        procedures[index].quantity = max(1, quantity)
    }

    func submitVisit() async -> Bool {
        guard !isSubmitting else { return false }

        isSubmitting = true
        errorMessage = nil

        do {
            // Validate procedures
            if !isNoShow && procedures.isEmpty {
                errorMessage = "Please add at least one procedure or mark as no-show"
                isSubmitting = false
                return false
            }

            // Validate date range
            let calendar = Calendar.current
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) ?? Date()
            let pastLimit = calendar.date(byAdding: .year, value: -10, to: Date()) ?? Date()
            if date >= tomorrow {
                errorMessage = "Visit date cannot be in the future"
                isSubmitting = false
                return false
            }
            if date < pastLimit {
                errorMessage = "Visit date is too far in the past"
                isSubmitting = false
                return false
            }

            // Format date as YYYY-MM-DD
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: date)

            // Format time as HH:mm:ss (if provided)
            var timeString: String?
            if let time = time {
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm:ss"
                timeString = timeFormatter.string(from: time)
            }

            // Create request
            let procedureRequests = procedures.map { proc in
                CreateProcedureRequest(
                    hcpcs: proc.hcpcs,
                    description: proc.description,
                    statusCode: proc.statusCode,
                    workRVU: proc.workRVU,
                    quantity: proc.quantity
                )
            }

            let request = CreateVisitRequest(
                date: dateString,
                time: timeString,
                notes: notes.isEmpty ? nil : notes,
                procedures: procedureRequests,
                isNoShow: isNoShow
            )

            // Submit to API (create or update)
            if let visitId = editingVisitId {
                _ = try await apiService.updateVisit(id: visitId, request)
            } else {
                _ = try await apiService.createVisit(request)
            }

            // Success
            showSuccessAlert = true
            if !isEditMode {
                resetForm()
            }
            isSubmitting = false
            return true

        } catch {
            errorMessage = error.localizedDescription
            isSubmitting = false
            return false
        }
    }

    func resetForm() {
        date = Date()
        time = nil
        notes = ""
        isNoShow = false
        procedures = []
        errorMessage = nil
    }

    var totalWorkRVU: Double {
        procedures.reduce(0) { $0 + ($1.workRVU * Double($1.quantity)) }
    }
}

// MARK: - Procedure Entry Model

struct ProcedureEntry: Identifiable, Equatable {
    let id: UUID
    let hcpcs: String
    let description: String
    let statusCode: String
    let workRVU: Double
    var quantity: Int
}
