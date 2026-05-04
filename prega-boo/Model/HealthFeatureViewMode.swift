import Foundation

/// Mom dashboard uses read-only “Health Passport” style UI; midwife child care keeps data-entry layout.
enum HealthFeatureViewMode: Equatable {
    case midwifeEntry
    case momReadOnly
}
