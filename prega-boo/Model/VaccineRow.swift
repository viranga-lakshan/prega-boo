import Foundation

struct VaccineRow: Identifiable, Hashable {
    let id: UUID
    let dateText: String
    let name: String
    let dosage: String

    init(id: UUID = UUID(), dateText: String, name: String, dosage: String) {
        self.id = id
        self.dateText = dateText
        self.name = name
        self.dosage = dosage
    }
}
