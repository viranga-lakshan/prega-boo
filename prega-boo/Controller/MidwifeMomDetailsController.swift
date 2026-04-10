import SwiftUI

final class MidwifeMomDetailsController {
    func loadModel() -> MidwifeMomDetailsModel {
        MidwifeMomDetailsModel(
            backgroundColor: Color(red: 1.0, green: 0.97, blue: 0.97),
            accentColor: Color(red: 0.94, green: 0.39, blue: 0.45),
            sectionLabel: "MEMBER PROFILE",
            addChildTitle: "Add Child",
            updateMomTitle: "Update Mom Details",
            childrenSectionTitle: "Registered Children",
            memberSinceTitle: "Member Since"
        )
    }
}
