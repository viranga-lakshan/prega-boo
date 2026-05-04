import Foundation

enum MomHealthAgeFormatting {
    private static let birthParser: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    static func ageLabelFromBirth(iso: String, reference: Date = Date()) -> String {
        guard let birth = birthParser.date(from: iso) else { return "" }
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: cal.startOfDay(for: birth), to: cal.startOfDay(for: reference))
        if let y = comps.year, y > 0 {
            let m = max(comps.month ?? 0, 0)
            if m > 0 { return "\(y) yr \(m) mo" }
            return "\(y) yr"
        }
        if let mo = comps.month, mo > 0 {
            return "\(mo) Months"
        }
        if let d = comps.day, d > 0 {
            return "\(d) days"
        }
        return "Newborn"
    }

    static func parseVisitDate(iso: String) -> Date? {
        birthParser.date(from: iso)
    }
}
