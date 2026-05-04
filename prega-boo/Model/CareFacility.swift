import CoreLocation
import Foundation

enum CareFacilityKind: String, Codable, CaseIterable {
    case hospital
    case maternal
}

struct CareFacility: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let shortName: String
    let kind: CareFacilityKind
    let latitude: Double
    let longitude: Double
    let area: String
    let phone: String
    /// Minutes from midnight local time (e.g. 480 = 8:00)
    let opensMinutes: Int
    let closesMinutes: Int

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func distanceMeters(from location: CLLocation?) -> CLLocationDistance? {
        guard let location else { return nil }
        return location.distance(from: CLLocation(latitude: latitude, longitude: longitude))
    }

    func isOpenNow(reference: Date = Date(), calendar: Calendar = .current) -> Bool {
        let comps = calendar.dateComponents([.hour, .minute], from: reference)
        let nowM = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        if closesMinutes < opensMinutes {
            return nowM >= opensMinutes || nowM < closesMinutes
        }
        return nowM >= opensMinutes && nowM < closesMinutes
    }
}
