import SwiftUI

struct PINPadView: View {
    let accentColor: Color
    @Binding var pin: String
    var maxDigits: Int = 4
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
                        .fill(i < pin.count ? accentColor : Color.white.opacity(0.35))
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
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.white.opacity(0.12))
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
                .foregroundStyle(Color.white.opacity(0.85))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
        }
        .buttonStyle(.plain)
    }
}
