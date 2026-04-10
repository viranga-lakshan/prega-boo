import SwiftUI

struct MidwifeMomsListView: View {
    let model: MidwifeMomsListModel
    let session: AuthSessionContext

    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var moms: [MomListRow] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var midwifeDistrict: String?

    @State private var offset = 0
    private let pageSize = 10

    var body: some View {
        ZStack {
            model.backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header

                        searchRow
                            .padding(.top, 18)

                        momsList
                            .padding(.top, 18)

                        loadMoreButton
                            .padding(.top, 20)
                            .padding(.bottom, 18)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 12)
                }

                bottomTabBar
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            loadFirstPage()
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { newValue in if !newValue { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var topBar: some View {
        HStack {
            Spacer()

            Text(model.title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(model.accentColor)

            Spacer()

            Button {
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Text(model.logoutTitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.5))

                    Image(systemName: "power")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.green.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(Color.white.opacity(0.55))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(model.sectionTitle)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.75))

            Rectangle()
                .fill(model.accentColor)
                .frame(width: 70, height: 4)
                .clipShape(Capsule())
        }
    }

    private var searchRow: some View {
        HStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.black.opacity(0.35))

                TextField(model.searchPlaceholder, text: $searchText)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(false)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button(action: {}) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 52, height: 48)

                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(model.accentColor)
                }
            }
        }
    }

    private var momsList: some View {
        LazyVStack(spacing: 16) {
            if isLoading && moms.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                if filteredMoms.isEmpty {
                    Text(emptyStateTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.45))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 26)
                } else {
                    ForEach(filteredMoms, id: \.id) { mom in
                        momCard(mom)
                    }
                }
            }
        }
    }

    private var emptyStateTitle: String {
        if let midwifeDistrict, !midwifeDistrict.isEmpty {
            return "No moms found for \(midwifeDistrict)."
        }
        return "No moms found."
    }

    private func momCard(_ mom: MomListRow) -> some View {
        NavigationLink {
            MidwifeMomDetailsView(
                model: MidwifeMomDetailsController().loadModel(),
                session: session,
                mom: mom
            )
        } label: {
            HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.06))
                    .frame(width: 70, height: 70)

                Image(systemName: "person.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.25))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(mom.fullName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.75))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.35))

                    Text(mom.district)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.55))
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    Text("ID:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.35))

                    Text(mom.displayId)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.35))
                }
                .padding(.top, 6)
            }

            Spacer(minLength: 8)

            HStack(spacing: 10) {
                Text(model.viewDetailsTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(model.accentColor)
                    .multilineTextAlignment(.trailing)

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(model.accentColor.opacity(0.85))
            }
        }
        .padding(18)
        .background(model.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }

    private var loadMoreButton: some View {
        Button(action: { loadNextPage() }) {
            HStack(spacing: 10) {
                Text(isLoading ? "Loading…" : model.loadMoreTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(model.accentColor)

                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(model.accentColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.35))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.18), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .disabled(isLoading)
    }

    private var bottomTabBar: some View {
        HStack {
            tabItem(title: "HOME", systemImage: "house", isSelected: false)
            tabItem(title: "SEARCH", systemImage: "magnifyingglass", isSelected: false)
            tabItem(title: "LISTS", systemImage: "list.bullet", isSelected: true)
            tabItem(title: "PROFILE", systemImage: "person", isSelected: false)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 18)
        .background(Color.white.opacity(0.65))
    }

    private func tabItem(title: String, systemImage: String, isSelected: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(model.accentColor.opacity(0.12))
                        .frame(width: 70, height: 44)
                }

                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? model.accentColor : Color.black.opacity(0.35))
            }

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }

    private var filteredMoms: [MomListRow] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return moms }

        return moms.filter {
            $0.fullName.localizedCaseInsensitiveContains(trimmed)
            || $0.district.localizedCaseInsensitiveContains(trimmed)
            || $0.displayId.contains(trimmed)
        }
    }

    private func normalizedDistrict(_ value: String?) -> String {
        (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func loadFirstPage() {
        offset = 0
        moms = []
        loadNextPage(resetOffset: true)
    }

    private func loadNextPage(resetOffset: Bool = false) {
        guard !isLoading else { return }
        isLoading = true

        Task {
            defer {
                Task { @MainActor in
                    isLoading = false
                }
            }
            do {
                // Fetch midwife district once (drives district-only moms list)
                if midwifeDistrict == nil {
                    let profile = try await MidwifeProfileRepository().fetchOwnProfile(
                        userId: session.userId,
                        accessToken: session.accessToken
                    )
                    guard let profile else {
                        await MainActor.run {
                            errorMessage = "Midwife profile not found for this account. Make sure midwife_profiles.user_id matches the logged-in auth user_id."
                        }
                        return
                    }
                    await MainActor.run {
                        midwifeDistrict = profile.district.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }

                let results = try await MidwifeMomsRepository().fetchMoms(
                    accessToken: session.accessToken,
                    limit: pageSize,
                    offset: offset
                )

                let districtKey = normalizedDistrict(midwifeDistrict)
                let visibleResults: [MomListRow]
                if districtKey.isEmpty {
                    visibleResults = results
                } else {
                    visibleResults = results.filter { normalizedDistrict($0.district) == districtKey }
                    #if DEBUG
                    let excluded = results.count - visibleResults.count
                    if excluded > 0 {
                        print("⚠️ Excluded \(excluded) moms due to district mismatch. Check Supabase RLS policies.")
                    }
                    #endif
                }

                await MainActor.run {
                    if resetOffset {
                        moms = visibleResults
                    } else {
                        moms.append(contentsOf: visibleResults)
                    }
                    offset += results.count
                }
            } catch SupabaseServiceError.httpError(let status, let body) {
                await MainActor.run {
                    errorMessage = "Failed to load moms (\(status)): \(SupabaseAuthService.humanMessage(fromBody: body))"
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load moms: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MidwifeMomsListView(
            model: MidwifeMomsListController().loadModel(),
            session: AuthSessionContext(userId: UUID(), accessToken: "test")
        )
    }
}
