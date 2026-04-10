import SwiftUI

struct AssetImage: View {
    let assetName: String
    let fallbackSystemName: String

    var body: some View {
        #if canImport(UIKit)
        if let uiImage = UIImage(named: assetName) {
            Image(uiImage: uiImage)
                .resizable()
        } else {
            Image(systemName: fallbackSystemName)
                .resizable()
        }
        #else
        Image(assetName)
            .resizable()
        #endif
    }
}
