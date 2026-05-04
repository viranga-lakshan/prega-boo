import SwiftUI

struct ChildCareDetailsView: View {
    let session: AuthSessionContext
    let mom: MomListRow
    let child: ChildProfile

    private let backgroundColor = Color(red: 1.0, green: 0.97, blue: 0.97)
    private let accentColor = Color(red: 0.94, green: 0.39, blue: 0.45)

    @Environment(\.dismiss) private var dismiss

    @State private var showVaccineDetails = false
    @State private var showClinicVisitDetails = false
    @State private var showGrowthTracking = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private let quickActions: [MomAndBabyQuickAction] = [
        MomAndBabyQuickAction(
            title: "Growth",
            subtitle: "MILESTONES",
            systemImageName: "chart.line.uptrend.xyaxis",
            backgroundColor: Color.green.opacity(0.10)
        ),
        MomAndBabyQuickAction(
            title: "Vaccine",
            subtitle: "HEALTH CARE",
            systemImageName: "syringe",
            backgroundColor: Color.purple.opacity(0.10)
        ),
        MomAndBabyQuickAction(
            title: "Schedule",
            subtitle: "ROUTINE",
            systemImageName: "calendar",
            backgroundColor: Color.blue.opacity(0.10)
        )
    ]

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    topBar
                        .padding(.horizontal, 18)
                        .padding(.top, 10)

                    profileCard
                        .padding(.horizontal, 18)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Baby Details")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.black.opacity(0.75))

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(Array(quickActions.enumerated()), id: \.offset) { _, action in
                                quickActionCard(action)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 28)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .background(
            NavigationLink(
                destination: VaccineDetailsMomView(
                    model: VaccineDetailsMomController().loadModel(),
                    session: session,
                    momUserId: nil,
                    childId: child.id
                ),
                isActive: $showVaccineDetails
            ) {
                EmptyView()
            }
        )
        .background(
            NavigationLink(
                destination: ClinicVisitDetailsMomView(
                    model: ClinicVisitDetailsMomController().loadModel(),
                    session: session,
                    momUserId: nil,
                    childId: child.id
                ),
                isActive: $showClinicVisitDetails
            ) {
                EmptyView()
            }
        )
        .background(
            NavigationLink(
                destination: GrowthTrackingMomView(
                    model: GrowthTrackingMomController().loadModel(),
                    session: session,
                    momUserId: nil,
                    childId: child.id
                ),
                isActive: $showGrowthTracking
            ) {
                EmptyView()
            }
        )
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("Baby\nDetails")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(accentColor)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Baby Details")

            Spacer()

            Button(action: {}) {
                Text("Edit")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .frame(width: 60, height: 44, alignment: .trailing)
            }
        }
    }

    private var profileCard: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 110, height: 110)
                    .shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: 10)

                Image(systemName: "face.smiling.fill")
                    .font(.system(size: 84))
                    .foregroundStyle(Color.black.opacity(0.12))

                Circle()
                    .fill(accentColor)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .offset(x: 40, y: 34)
            }

            Text(child.fullName)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.black.opacity(0.75))

            Text("Born \(formattedDOB(child.birthDate)) • Mother: \(mom.fullName)")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.black.opacity(0.45))

            HStack(spacing: 14) {
                statPill(value: "0", label: "VISITS")
                statPill(value: "0", label: "VACCINES")
            }
            .padding(.top, 6)
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(accentColor)

            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.45))
        }
        .frame(width: 110, height: 54)
        .background(Color.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func quickActionCard(_ action: MomAndBabyQuickAction) -> some View {
        Button(action: {
            if action.title == "Vaccine" {
                showVaccineDetails = true
            } else if action.title == "Schedule" {
                showClinicVisitDetails = true
            } else if action.title == "Growth" {
                showGrowthTracking = true
            }
        }) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 48, height: 48)

                    Image(systemName: action.systemImageName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(accentColor)
                }

                Text(action.title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.75))

                Text(action.subtitle)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.45))
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .padding(18)
            .background(action.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
    }

    private func formattedDOB(_ iso: String) -> String {
        let input = DateFormatter()
        input.locale = Locale(identifier: "en_US_POSIX")
        input.timeZone = TimeZone(secondsFromGMT: 0)
        input.dateFormat = "yyyy-MM-dd"

        let output = DateFormatter()
        output.locale = Locale(identifier: "en_US_POSIX")
        output.dateFormat = "MMM d, yyyy"

        guard let date = input.date(from: iso) else { return iso }
        return output.string(from: date)
    }
}

#Preview {
    NavigationStack {
        ChildCareDetailsView(
            session: AuthSessionContext(userId: UUID(), accessToken: ""),
            mom: MomListRow(id: UUID(), userId: UUID(), fullName: "Mom Name", district: "District"),
            child: ChildProfile(
                id: UUID(),
                momUserId: UUID(),
                fullName: "Baby Name",
                birthDate: "2026-01-01",
                gender: nil,
                deliveryMethod: nil,
                notes: nil,
                idPhotoPath: nil
            )
        )
    }
}
