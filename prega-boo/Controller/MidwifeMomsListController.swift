import SwiftUI

final class MidwifeMomsListController {
    func loadModel() -> MidwifeMomsListModel {
        MidwifeMomsListModel(
            title: "Moms List",
            logoutTitle: "Log Out",
            sectionTitle: "Active Registrations",
            searchPlaceholder: "Find a mom…",
            viewDetailsTitle: "View\nDetails",
            loadMoreTitle: "Load More Members",
            backgroundColor: Color(red: 1.0, green: 0.97, blue: 0.97),
            accentColor: Color(red: 0.94, green: 0.39, blue: 0.45),
            cardBackground: Color.white
        )
    }
}
