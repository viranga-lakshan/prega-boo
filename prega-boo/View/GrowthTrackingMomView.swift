import SwiftUI

struct GrowthTrackingMomView: View {
    let model: GrowthTrackingMomModel

    @Environment(\.dismiss) private var dismiss

    @State private var weightText: String = ""
    @State private var heightText: String = ""

    @State private var selectedMilestones: Set<String> = ["First Smile"]
    @State private var notes: String = ""

    private let milestones: [String] = [
        "First Smile",
        "Rolled Over",
        "Grasping"
    ]

    var body: some View {
        ZStack {
            model.backgroundColor
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                        .padding(.top, 10)

                    headerCard

                    chartCard

                    newEntryRow
                        .padding(.top, 2)

                    weightField

                    heightField

                    milestonesSection

                    notesBox

                    saveButton
                        .padding(.top, 8)
                        .padding(.bottom, 28)
                }
                .padding(.horizontal, 18)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 46, height: 46)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.45))
                }
            }

            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.65))
                    .frame(width: 62, height: 62)

                Image(systemName: "figure.pregnant")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(model.accentColor)
            }
        }
    }

    private var headerCard: some View {
        Text(model.title)
            .font(.system(size: 42, weight: .bold, design: .rounded))
            .foregroundStyle(Color.black.opacity(0.78))
            .padding(.horizontal, 6)
            .padding(.top, 4)
            .padding(.bottom, 6)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(model.cardTitle)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.75))

                    Text(model.cardSubtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.black.opacity(0.45))
                }

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    Circle()
                        .fill(model.accentColor)
                        .frame(width: 6, height: 6)

                    Text(model.cardBadgeTitle)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.55))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.7))
                .clipShape(Capsule())
            }

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                    .frame(height: 220)

                GrowthLineChart(accentColor: model.accentColor)
                    .frame(height: 200)
                    .padding(.horizontal, 12)
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var newEntryRow: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(model.accentColor.opacity(0.18))
                    .frame(width: 44, height: 44)

                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(model.accentColor)
            }

            Text(model.newEntryTitle)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.75))

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.25))
        }
    }

    private var weightField: some View {
        labeledUnitField(label: model.weightLabel, unit: model.weightUnit, text: $weightText)
    }

    private var heightField: some View {
        labeledUnitField(label: model.heightLabel, unit: model.heightUnit, text: $heightText)
    }

    private func labeledUnitField(label: String, unit: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.55))

            HStack {
                TextField("0", text: text)
                    .keyboardType(.decimalPad)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)

                Text(unit)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.45))
                    .padding(.trailing, 16)
            }
            .background(model.accentColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(model.milestonesTitle)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.55))

            HStack(spacing: 10) {
                    ForEach(milestones, id: \.self) { m in
                    milestonePill(title: m)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func milestonePill(title: String) -> some View {
        let isSelected = selectedMilestones.contains(title)

        return Button {
            if isSelected {
                selectedMilestones.remove(title)
            } else {
                selectedMilestones.insert(title)
            }
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? Color.black.opacity(0.75) : Color.black.opacity(0.55))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? model.accentColor.opacity(0.25) : Color.white.opacity(0.75))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var notesBox: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $notes)
                .frame(minHeight: 140)
                .padding(14)
                .background(model.accentColor.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(model.notesPlaceholder)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.black.opacity(0.30))
                    .padding(.horizontal, 22)
                    .padding(.vertical, 22)
            }
        }
    }

    private var saveButton: some View {
        Button(action: {}) {
            Text(model.saveButtonTitle)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(model.accentColor.opacity(0.85))
                .clipShape(Capsule())
        }
    }
}

private struct GrowthLineChart: View {
    let accentColor: Color

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height

            ZStack {
                VStack(spacing: 0) {
                    Divider().opacity(0.15)
                    Spacer()
                    Divider().opacity(0.15)
                    Spacer()
                    Divider().opacity(0.15)
                }

                let points: [CGPoint] = [
                    CGPoint(x: 0.0 * w, y: 0.72 * h),
                    CGPoint(x: 0.28 * w, y: 0.54 * h),
                    CGPoint(x: 0.55 * w, y: 0.43 * h),
                    CGPoint(x: 0.78 * w, y: 0.32 * h),
                    CGPoint(x: 1.0 * w, y: 0.28 * h)
                ]

                Path { path in
                    path.move(to: points[0])
                    for p in points.dropFirst() {
                        path.addLine(to: p)
                    }
                }
                .stroke(accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                ForEach(Array(points.dropFirst().enumerated()), id: \.offset) { _, p in
                    Circle()
                        .fill(accentColor)
                        .frame(width: 10, height: 10)
                        .position(x: p.x, y: p.y)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        GrowthTrackingMomView(model: GrowthTrackingMomController().loadModel())
    }
}
