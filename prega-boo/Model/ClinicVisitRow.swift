import Foundation

struct ClinicVisitRow: Identifiable, Hashable {
    let id: UUID
    let dateText: String
    let timeText: String
    let purpose: String
    /// Raw `yyyy-MM-dd` from API for sorting (mom read-only UI).
    let visitDateISO: String?

    init(id: UUID = UUID(), dateText: String, timeText: String, purpose: String, visitDateISO: String? = nil) {
        self.id = id
        self.dateText = dateText
        self.timeText = timeText
        self.purpose = purpose
        self.visitDateISO = visitDateISO
    }
}
