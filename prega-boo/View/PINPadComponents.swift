import SwiftUI

struct PINPadView: View {
    let accentColor: Color
    @Binding var pin: String
    var maxDigits: Int = 4
    var digitTextColor: Color = .white
    var digitBackgroundColor: Color = Color.white.opacity(0.12)
    var emptyDotColor: Color = Color.white.opacity(0.35)
    var deleteIconColor: Color = Color.white.opacity(0.85)
    var onComplete: ((String) -> Void)?

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 10) {
                ForEach(0..<maxDigits, id: \.self) { i in
                    Circle()
                        .fill(i < pin.count ? accentColor : emptyDotColor)
                        .frame(width: 12, height: 12)
                }
            }
            .padding(.bottom, 8)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(1...9, id: \.self) { n in
                    digitButton("\(n)")
                }
                Color.clear.frame(height: 56)
                digitButton("0")
                deleteButton
            }
        }
    }

    private func digitButton(_ d: String) -> some View {
        Button {
            guard pin.count < maxDigits else { return }
            pin += d
            if pin.count == maxDigits {
                onComplete?(pin)
            }
        } label: {
            Text(d)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundStyle(digitTextColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(digitBackgroundColor)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var deleteButton: some View {
        Button {
            if !pin.isEmpty { pin.removeLast() }
        } label: {
            Image(systemName: "delete.left.fill")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(deleteIconColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
        }
        .buttonStyle(.plain)
    }
}
