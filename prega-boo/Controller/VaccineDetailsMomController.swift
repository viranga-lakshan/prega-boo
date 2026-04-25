import SwiftUI

final class VaccineDetailsMomController {
    func loadModel() -> VaccineDetailsMomModel {
        VaccineDetailsMomModel(
            backgroundColor: Color(red: 1.0, green: 0.97, blue: 0.97),
            accentColor: Color(red: 0.94, green: 0.39, blue: 0.45),
            title: "Vaccine Details Mom",
            vaccineNameLabel: "Enter Vaccine Name",
            vaccineNamePlaceholder: "",
            dosageLabel: "Enter Dosage",
            dosagePlaceholder: "",
            addButtonTitle: "ADD",
            listTitle: "Vaccine",
            dateColumnTitle: "Date",
            nameColumnTitle: "Name",
            dosageColumnTitle: "Dosage"
        )
    }
}
