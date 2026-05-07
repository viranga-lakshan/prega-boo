import Combine
import Foundation
import SwiftUI

/// Routes deep-links coming from outside the app (Home Screen widget taps,
/// universal links, etc.) into navigation flags that views can observe.
@MainActor
final class DeepLinkRouter: ObservableObject {
    static let shared = DeepLinkRouter()

    /// When set to `true`, the mom-side dashboard should push the
    /// Mom & Baby Details screen. The dashboard resets the flag after handling.
    @Published var shouldOpenMomBabyDetails: Bool = false

    private init() {}

    /// Returns `true` if the URL was consumed by the deep-link router.
    /// OAuth callback URLs (`cw.prega-boo://login-callback`) are deliberately
    /// ignored here so they keep flowing through the existing OAuth handler.
    @discardableResult
    func handle(_ url: URL) -> Bool {
        guard url.scheme == "cw.prega-boo" else { return false }

        switch url.host {
        case "widget-nav":
            let target = url.pathComponents.dropFirst().first
            switch target {
            case "mom-baby-details":
                shouldOpenMomBabyDetails = true
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
}
