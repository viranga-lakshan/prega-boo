import SwiftUI

final class ClinicVisitDetailsMomController {
    func loadModel() -> ClinicVisitDetailsMomModel {
        ClinicVisitDetailsMomModel(
            backgroundColor: Color(red: 1.0, green: 0.97, blue: 0.97),
            accentColor: Color(red: 0.94, green: 0.39, blue: 0.45),
            title: "Clinic Visit Details Mom",
            visitDateTitle: "Visit Date",
            visitTimeTitle: "Visit Time",
            purposeTitle: "Purpose",
            purposePlaceholder: "Enter Purpose",
            addButtonTitle: "ADD",
            listTitle: "Visit Details",
            dateColumnTitle: "Date",
            timeColumnTitle: "Time",
            purposeColumnTitle: "Purpose"
        )
    }
}
