import SwiftUI

struct BabyDetailsView: View {
    let model: BabyDetailsModel
    let session: AuthSessionContext?
    let child: ChildProfile?
    let healthFeatureMode: HealthFeatureViewMode

    init(
        model: BabyDetailsModel,
        session: AuthSessionContext? = nil,
        child: ChildProfile? = nil,
        healthFeatureMode: HealthFeatureViewMode = .momReadOnly
    ) {
        self.model = model
        self.session = session
        self.child = child
        self.healthFeatureMode = healthFeatureMode
    }

    @Environment(\.dismiss) private var dismiss

    @State private var showVaccineDetails = false
    @State private var showClinicVisitDetails = false
    @State private var showGrowthTracking = false

    @State private var latestWeight: String?
    @State private var latestHeight: String?

    private let actionColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private var subtitleText: String {
        if let child {
            let age = MomHealthAgeFormatting.ageLabelFromBirth(iso: child.birthDate)
            return "\(age) • Healthy growth tracking"
        }
        return model.subtitle
    }

    private var metricsToShow: [BabyMetric] {
        if let w = latestWeight, let h = latestHeight {
            return [
                BabyMetric(title: "WEIGHT", value: w, unit: "kg"),
                BabyMetric(title: "HEIGHT", value: h, unit: "cm"),
                BabyMetric(title: "SLEEP", value: "—", unit: "hrs")
            ]
        }
        return model.metrics
    }

    var body: some View {
        ZStack {
            model.backgroundColor
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    topBar
                        .padding(.horizontal, 18)
                        .padding(.top, 10)

                    hero
                        .padding(.horizontal, 18)

                    metricsRow
                        .padding(.horizontal, 18)

                    LazyVGrid(columns: actionColumns, spacing: 16) {
                        ForEach(Array(model.quickActions.enumerated()), id: \.offset) { _, action in
                            quickActionCard(action)
                        }
                    }
                    .padding(.horizontal, 18)

                    verifiedCard
                        .padding(.horizontal, 18)
                        .padding(.bottom, 28)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task { await loadLatestGrowth() }
        .background(
            NavigationLink(
                destination: Group {
                    if let session, let child {
                        VaccineDetailsMomView(
                            model: VaccineDetailsMomController().loadModel(),
                            session: session,
                            momUserId: nil,
                            childId: child.id,
                            mode: healthFeatureMode
                        )
                    } else { EmptyView() }
                },
                isActive: $showVaccineDetails
            ) { EmptyView() }
        )
        .background(
            NavigationLink(
                destination: Group {
                    if let session, let child {
                        ClinicVisitDetailsMomView(
                            model: ClinicVisitDetailsMomController().loadModel(),
                            session: session,
                            momUserId: nil,
                            childId: child.id,
                            mode: healthFeatureMode
                        )
                    } else { EmptyView() }
                },
                isActive: $showClinicVisitDetails
            ) { EmptyView() }
        )
        .background(
            NavigationLink(
                destination: Group {
                    if let session, let child {
                        GrowthTrackingMomView(
                            model: GrowthTrackingMomController().loadModel(),
                            session: session,
                            momUserId: nil,
                            childId: child.id,
                            mode: healthFeatureMode,
                            ageHeadline: MomHealthAgeFormatting.ageLabelFromBirth(iso: child.birthDate)
                        )
                    } else { EmptyView() }
                },
                isActive: $showGrowthTracking
            ) { EmptyView() }
        )
    }

    private func loadLatestGrowth() async {
        guard let session, let child else { return }
        do {
            let recs = try await ChildGrowthRecordsRepository().fetchRecords(
                childId: child.id,
                accessToken: session.accessToken
            )
            let sorted = recs.sorted { $0.measuredOn > $1.measuredOn }
            guard let g = sorted.first else { return }
            await MainActor.run {
                latestWeight = String(format: "%.1f", g.weightKg)
                latestHeight = String(format: "%.1f", g.heightCm)
            }
        } catch {
            await MainActor.run {
                latestWeight = nil
                latestHeight = nil
            }
        }
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

            Text(model.navTitle)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(model.accentColor)
                .frame(maxWidth: .infinity)

            Spacer()

            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 32, height: 32)

                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.black.opacity(0.25))
            }
            .frame(width: 60, height: 44, alignment: .trailing)
        }
    }

    private var hero: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(model.accentColor.opacity(0.12))
                    .frame(width: 160, height: 160)

                Circle()
                    .stroke(model.accentColor.opacity(0.8), lineWidth: 3)
                    .frame(width: 160, height: 160)

                Image(systemName: "face.smiling")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(model.accentColor)
            }

            HStack(spacing: 8) {
                Image(systemName: "medal.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(model.accentColor)

                Text(model.badgeTitle)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.55))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.7))
            .clipShape(Capsule())

            Text(model.babyName)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.75))

            Text(subtitleText)
                .font(.system(size: 13))
                .foregroundStyle(Color.black.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }

    private var metricsRow: some View {
        HStack(spacing: 12) {
            ForEach(Array(metricsToShow.enumerated()), id: \.offset) { _, metric in
                metricCard(metric)
            }
        }
    }

    private func metricCard(_ metric: BabyMetric) -> some View {
        VStack(spacing: 8) {
            Text(metric.title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.45))

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(metric.value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.72))

                Text(metric.unit)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.45))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 70)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func quickActionCard(_ action: MomAndBabyQuickAction) -> some View {
        Button(action: {
            guard session != nil, child != nil else { return }
            switch action.title {
            case "Growth": showGrowthTracking = true
            case "Vaccine": showVaccineDetails = true
            case "Schedule": showClinicVisitDetails = true
            default: break
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
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(model.accentColor.opacity(0.9))
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .padding(18)
            .background(action.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
    }

    private var verifiedCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(model.accentColor.opacity(0.18))
                    .frame(width: 44, height: 44)

                Image(systemName: "lock.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(model.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(model.verifiedTitle)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.75))

                Text(model.verifiedBody)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.black.opacity(0.45))
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(model.accentColor.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        BabyDetailsView(model: BabyDetailsController().loadModel(babyName: "Niromi"))
    }
}
