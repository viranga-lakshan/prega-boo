import Foundation

enum CareFacilitiesLoader {
    static func loadFromBundle() -> [CareFacility] {
        guard let url = Bundle.main.url(forResource: "CareFacilities", withExtension: "json") else {
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([CareFacility].self, from: data)
        } catch {
            return []
        }
    }
}
