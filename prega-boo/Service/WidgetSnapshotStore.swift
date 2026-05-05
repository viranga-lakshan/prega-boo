import Foundation

#if canImport(WidgetKit)
import WidgetKit
#endif

struct MomWidgetSnapshot: Codable {
    let momName: String
    let district: String
    let trackerMessage: String
    let updatedAtISO: String
}

enum WidgetSnapshotStore {
    static let appGroupId = "group.cw.prega-boo"
    private static let key = "mom.widget.snapshot.v1"

    static func save(snapshot: MomWidgetSnapshot) {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    static func load() -> MomWidgetSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(MomWidgetSnapshot.self, from: data) else {
            return nil
        }
        return decoded
    }

    static func publishForDashboard(name: String, district: String) {
        let iso = ISO8601DateFormatter().string(from: Date())
        let snapshot = MomWidgetSnapshot(
            momName: name.isEmpty ? "Mom" : name,
            district: district.isEmpty ? "Your district" : district,
            trackerMessage: "Open Prega Boo to log weight, kicks, mood, and pregnancy progress.",
            updatedAtISO: iso
        )
        save(snapshot: snapshot)
    }
}
