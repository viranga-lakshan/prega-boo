import SwiftUI

struct MomAndBabyDetailsView: View {
    let model: MomAndBabyDetailsModel

    @Environment(\.dismiss) private var dismiss

    @State private var selectedBaby: BabySummary?
    @State private var showBabyDetails = false

    @State private var showVaccineDetails = false
    @State private var showClinicVisitDetails = false
    @State private var showGrowthTracking = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ZStack {
            model.backgroundColor
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    topBar
                        .padding(.horizontal, 18)
                        .padding(.top, 10)

                    profileCard
                        .padding(.horizontal, 18)

                    VStack(alignment: .leading, spacing: 14) {
                        Text(model.momDetailsTitle)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.black.opacity(0.75))

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(Array(model.quickActions.enumerated()), id: \.offset) { _, action in
                                quickActionCard(action)
                            }
                        }
                    }
                    .padding(.horizontal, 18)

                    babiesCard
                        .padding(.horizontal, 18)
                        .padding(.bottom, 28)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .background(
            NavigationLink(
                destination: Group {
                    if let selectedBaby {
                        BabyDetailsView(model: BabyDetailsController().loadModel(babyName: selectedBaby.name))
                    } else {
                        EmptyView()
                    }
                },
                isActive: $showBabyDetails
            ) {
                EmptyView()
            }
        )
        .background(
            NavigationLink(
                destination: VaccineDetailsMomView(model: VaccineDetailsMomController().loadModel()),
                isActive: $showVaccineDetails
            ) {
                EmptyView()
            }
        )
        .background(
            NavigationLink(
                destination: ClinicVisitDetailsMomView(model: ClinicVisitDetailsMomController().loadModel()),
                isActive: $showClinicVisitDetails
            ) {
                EmptyView()
            }
        )
        .background(
            NavigationLink(
                destination: GrowthTrackingMomView(model: GrowthTrackingMomController().loadModel()),
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
                    .foregroundStyle(model.accentColor)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(model.title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(model.accentColor)
                .frame(maxWidth: .infinity)

            Spacer()

            Button(action: {}) {
                Text(model.editTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(model.accentColor)
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

                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 110))
                    .foregroundStyle(Color.black.opacity(0.18))

                Circle()
                    .fill(model.accentColor)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .offset(x: 40, y: 34)
            }

            Text(model.profileName)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.black.opacity(0.75))

            Text(model.profileSubtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.black.opacity(0.45))

            HStack(spacing: 14) {
                ForEach(Array(model.stats.enumerated()), id: \.offset) { _, stat in
                    statPill(stat)
                }
            }
            .padding(.top, 6)
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func statPill(_ stat: MomAndBabyStat) -> some View {
        VStack(spacing: 4) {
            Text(stat.value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(model.accentColor)

            Text(stat.label)
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
                        .foregroundStyle(model.accentColor)
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

    private var babiesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(model.babiesDetailsTitle)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.75))

                Spacer()

                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.35))
                    .frame(width: 44, height: 44)
            }

            VStack(spacing: 14) {
                ForEach(Array(model.babies.enumerated()), id: \.offset) { _, baby in
                    Button(action: {
                        selectedBaby = baby
                        showBabyDetails = true
                    }) {
                        babyRow(baby)
                    }
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func babyRow(_ baby: BabySummary) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 44, height: 44)

                Image(systemName: "person.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(model.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(baby.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.72))

                Text(baby.ageText)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.black.opacity(0.45))
            }

            Spacer()

            Text(baby.statusText)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(model.accentColor)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    NavigationStack {
        MomAndBabyDetailsView(model: MomAndBabyDetailsController().loadModel())
    }
}
