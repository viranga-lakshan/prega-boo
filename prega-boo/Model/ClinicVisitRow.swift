import Foundation

struct ClinicVisitRow: Identifiable, Hashable {
    let id: UUID
    let dateText: String
    let timeText: String
    let purpose: String

    init(id: UUID = UUID(), dateText: String, timeText: String, purpose: String) {
        self.id = id
        self.dateText = dateText
        self.timeText = timeText
        self.purpose = purpose
    }
}
