import SwiftUI

struct MomRemindersView: View {
    let backgroundColor: Color
    let accentColor: Color
    let session: AuthSessionContext?

    @Environment(\.dismiss) private var dismiss

    @AppStorage("momReminders.pushAlertsOn") private var pushAlertsOn = true
    @AppStorage("momReminders.muteAllOn") private var muteAllOn = false

    @State private var upcoming: [MomUpcomingReminderItem] = []
    @State private var history: [MomReminderHistoryItem] = []
    @State private var disabledReminderIds: Set<UUID> = []
    @State private var isLoading = false
    @State private var loadError: String?

    @State private var showAddSheet = false
    @State private var newTitle = ""
    @State private var newReminderDate = Date()
    @State private var newReminderTime = Date()
    @State private var newTag: MomReminderTagStyle = .health
    @State private var newMetadata = ""
    @State private var isSavingReminder = false

    private var deepMaroon: Color { Color(red: 0.42, green: 0.11, blue: 0.20) }
    private var newReminderTimeText: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current
        df.dateFormat = "h:mm a"
        return df.string(from: newReminderTime)
    }

    init(
        backgroundColor: Color,
        accentColor: Color,
        session: AuthSessionContext? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.accentColor = accentColor
        self.session = session
    }

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    topBar
                        .padding(.top, 8)

                    settingsRow

                    if let loadError {
                        Text(loadError)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.red.opacity(0.85))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    upcomingSection

                    pastHistorySection
                        .padding(.bottom, 28)
                }
                .padding(.horizontal, 18)
            }
            .refreshable { await reloadFromRemote() }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showAddSheet) {
            addReminderSheet
        }
        .task {
            disabledReminderIds = MomRemindersLocalStore.shared.loadDisabledReminderIds()
            await reloadFromRemote()
        }
        .onChange(of: pushAlertsOn) { _, _ in
            Task { await syncScheduledNotifications() }
        }
        .onChange(of: muteAllOn) { _, _ in
            Task { await syncScheduledNotifications() }
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(deepMaroon)
                    .frame(width: 44, height: 44)
            }

            Text("Reminders")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(deepMaroon)
                .frame(maxWidth: .infinity)

            HStack(spacing: 14) {
                Image(systemName: "calendar")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(deepMaroon)

                Circle()
                    .fill(accentColor.opacity(0.35))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(deepMaroon.opacity(0.8))
                    )
            }
        }
    }

    private var settingsRow: some View {
        HStack(spacing: 12) {
            settingCard(
                icon: "bell.fill",
                title: "Push Alerts",
                subtitle: "Instant updates",
                isOn: $pushAlertsOn
            )
            settingCard(
                icon: "bell.slash.fill",
                title: "Mute All",
                subtitle: "Focus mode",
                isOn: $muteAllOn
            )
        }
    }

    private func settingCard(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accentColor)
                Spacer()
                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(accentColor)
            }
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(deepMaroon)
            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.42))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 3)
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Upcoming")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(deepMaroon)
                Spacer()
                Button("Add New") {
                    newTitle = ""
                    newReminderDate = Date()
                    newReminderTime = Date()
                    newMetadata = ""
                    newTag = .health
                    showAddSheet = true
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(accentColor)
                .disabled(session == nil)
                .opacity(session == nil ? 0.45 : 1)
            }

            if muteAllOn {
                Text("Mute All is on — reminders stay listed but won’t notify.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.45))
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }

            if upcoming.isEmpty, !isLoading {
                Text(session == nil ? "Sign in to load clinic visits and reminders from your Health Passport." : "No upcoming visits or reminders. Your midwife can add clinic dates, or tap Add New.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.45))
            }

            ForEach(upcoming) { item in
                upcomingCard(
                    item: item,
                    isOn: reminderToggleBinding(for: item)
                )
            }
        }
    }

    private func reminderToggleBinding(for item: MomUpcomingReminderItem) -> Binding<Bool> {
        switch item.source {
        case .clinicMom, .clinicChild:
            return Binding(
                get: { !disabledReminderIds.contains(item.id) },
                set: { enabled in
                    if enabled {
                        disabledReminderIds.remove(item.id)
                    } else {
                        disabledReminderIds.insert(item.id)
                    }
                    MomRemindersLocalStore.shared.saveDisabledReminderIds(disabledReminderIds)
                    Task { await syncScheduledNotifications() }
                }
            )
        case .customDatabase:
            return Binding(
                get: {
                    upcoming.first(where: { $0.id == item.id })?.dbNotificationEnabled ?? item.dbNotificationEnabled
                },
                set: { enabled in
                    guard let session else { return }
                    Task { @MainActor in
                        do {
                            try await MomRemindersRepository().updateNotificationEnabled(
                                reminderId: item.id,
                                enabled: enabled,
                                accessToken: session.accessToken
                            )
                            if let idx = upcoming.firstIndex(where: { $0.id == item.id }) {
                                upcoming[idx].dbNotificationEnabled = enabled
                            }
                            loadError = nil
                            await syncScheduledNotifications()
                        } catch {
                            loadError = "Could not update reminder: \(error.localizedDescription)"
                        }
                    }
                }
            )
        }
    }

    private func upcomingCard(item: MomUpcomingReminderItem, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(accentColor.opacity(0.14))
                    .frame(width: 48, height: 48)

                Image(systemName: item.iconSystemName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(deepMaroon)

                Text(item.scheduleText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.45))

                HStack(spacing: 8) {
                    Text(item.tag.label)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(item.tag.tagColor)
                        .clipShape(Capsule())

                    Text(item.metadata)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.4))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(accentColor)
                .disabled(muteAllOn || !pushAlertsOn)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
    }

    private var pastHistorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PAST HISTORY")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.38))
                .tracking(0.6)

            if history.isEmpty, !isLoading, session != nil {
                Text("Completed visits, growth, and vaccines will show here.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.45))
            }

            VStack(alignment: .leading, spacing: 16) {
                ForEach(history) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(Color.black.opacity(0.22))
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(deepMaroon)
                            Text(item.completedText)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.black.opacity(0.42))
                        }
                    }
                }
            }
        }
    }

    private var addReminderSheet: some View {
        NavigationStack {
            Form {
                Section("Reminder") {
                    TextField("Title", text: $newTitle)
                    DatePicker("Date", selection: $newReminderDate, displayedComponents: .date)
                    DatePicker("Time", selection: $newReminderTime, displayedComponents: .hourAndMinute)
                    TextField("Note (doctor, checkup…)", text: $newMetadata)
                }
                Section("Category") {
                    Picker("Tag", selection: $newTag) {
                        ForEach(MomReminderTagStyle.allCases) { tag in
                            Text(tag.label).tag(tag)
                        }
                    }
                }
            }
            .navigationTitle("New reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        let timeRaw = newReminderTimeText
                        guard let session, !title.isEmpty, !timeRaw.isEmpty else { return }
                        let meta = newMetadata.trimmingCharacters(in: .whitespacesAndNewlines)
                        let dateISO = MomRemindersDataService.localCalendarDayISO(from: newReminderDate)
                        let icon = newTag == .health ? "calendar" : "syringe"
                        isSavingReminder = true
                        Task {
                            defer { Task { @MainActor in isSavingReminder = false } }
                            do {
                                try await MomRemindersRepository().insertReminder(
                                    momUserId: session.userId,
                                    createdByUserId: session.userId,
                                    childId: nil,
                                    title: title,
                                    reminderDateISO: dateISO,
                                    reminderTimeText: timeRaw,
                                    metadata: meta.isEmpty ? nil : meta,
                                    reminderTag: newTag.rawValue,
                                    iconName: icon,
                                    accessToken: session.accessToken
                                )
                                await MainActor.run {
                                    showAddSheet = false
                                    loadError = nil
                                }
                                await reloadFromRemote()
                            } catch {
                                await MainActor.run {
                                    loadError = "Could not save reminder: \(error.localizedDescription)"
                                }
                            }
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(session == nil || isSavingReminder)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @MainActor
    private func reloadFromRemote() async {
        loadError = nil
        disabledReminderIds = MomRemindersLocalStore.shared.loadDisabledReminderIds()

        guard let session else {
            upcoming = MomRemindersController.upcomingDefaults()
            history = MomRemindersController.historyDefaults()
            await syncScheduledNotifications()
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let (remoteUpcoming, remoteHistory) = try await MomRemindersDataService.load(session: session)
            upcoming = remoteUpcoming
            history = remoteHistory
        } catch SupabaseServiceError.httpError(let status, let body) {
            loadError = "Could not load (\(status)): \(SupabaseAuthService.humanMessage(fromBody: body))"
            upcoming = []
            history = []
        } catch {
            loadError = "Could not load: \(error.localizedDescription)"
            upcoming = []
            history = []
        }

        await syncScheduledNotifications()
    }

    @MainActor
    private func syncScheduledNotifications() async {
        await MomRemindersNotificationService.shared.reschedule(
            upcoming: upcoming,
            disabledReminderIds: disabledReminderIds,
            pushAlertsEnabled: pushAlertsOn,
            muteAll: muteAllOn
        )
    }

}

#Preview {
    NavigationStack {
        MomRemindersView(
            backgroundColor: Color(red: 1.0, green: 0.97, blue: 0.97),
            accentColor: Color(red: 0.94, green: 0.39, blue: 0.45),
            session: nil
        )
    }
}
