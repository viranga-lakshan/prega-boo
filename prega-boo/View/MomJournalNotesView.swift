import SwiftUI

/// Shared "Care Notes / Journal" screen.
///
/// - In `.midwifeEntry` mode, the midwife can add, edit (only her own) and delete (only her own) notes.
/// - In `.momReadOnly` mode, the mom sees a read-only timeline of notes written about her care.
///
/// Notes are persisted to `public.mom_journal_notes` and protected by RLS so a midwife may only
/// write notes for moms in her own district, and a mom may only read notes attached to her account.
struct MomJournalNotesView: View {
    let model: MomJournalNotesModel
    let session: AuthSessionContext?
    let momUserId: UUID?
    /// When set, the screen shows notes attached to this baby; when `nil`, mom-level notes.
    let childId: UUID?
    /// Optional name shown in headings (e.g. baby's first name). Falls back to generic copy.
    let subjectName: String?
    let mode: HealthFeatureViewMode

    @Environment(\.dismiss) private var dismiss

    @State private var notes: [MomJournalNote] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var showEditor = false
    @State private var editingNote: MomJournalNote?
    @State private var titleText = ""
    @State private var bodyText = ""
    @State private var isSaving = false

    @State private var pendingDelete: MomJournalNote?

    private var deepMaroon: Color { Color(red: 0.42, green: 0.11, blue: 0.20) }

    init(
        model: MomJournalNotesModel,
        session: AuthSessionContext? = nil,
        momUserId: UUID? = nil,
        childId: UUID? = nil,
        subjectName: String? = nil,
        mode: HealthFeatureViewMode = .midwifeEntry
    ) {
        self.model = model
        self.session = session
        self.momUserId = momUserId
        self.childId = childId
        self.subjectName = subjectName
        self.mode = mode
    }

    private var resolvedMomHeader: String {
        if let subjectName, childId != nil {
            return "Notes about \(subjectName)"
        }
        return model.momHeader
    }

    private var resolvedMomSubtitle: String {
        if let subjectName, childId != nil {
            return "Care notes from your midwife about \(subjectName), newest first."
        }
        return model.momSubtitle
    }

    private var resolvedMidwifeHeader: String {
        if let subjectName, childId != nil {
            return "Care notes for \(subjectName)"
        }
        return model.midwifeHeader
    }

    private var resolvedMidwifeSubtitle: String {
        if let subjectName, childId != nil {
            return "Add observations, recommendations and follow-up plans for \(subjectName)."
        }
        return model.midwifeSubtitle
    }

    var body: some View {
        ZStack {
            model.backgroundColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                        .padding(.top, 8)

                    titleBlock

                    if isLoading && notes.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                    } else if notes.isEmpty {
                        emptyState
                    } else {
                        notesList
                    }

                    if mode == .midwifeEntry {
                        addNoteButton
                            .padding(.top, 4)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 18)
            }
            .refreshable { await reload() }
        }
        .navigationBarBackButtonHidden(true)
        .task { await reload() }
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
        .sheet(isPresented: $showEditor, onDismiss: resetEditingState) {
            editorSheet
        }
        .confirmationDialog(
            "Delete this note?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { newValue in if !newValue { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let note = pendingDelete {
                    Task { await deleteNote(note) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(pendingDelete?.title ?? "")
        }
    }

    // MARK: - Header

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(deepMaroon)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(model.title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(deepMaroon)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(mode == .momReadOnly ? resolvedMomHeader : resolvedMidwifeHeader)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.78))

            Text(mode == .momReadOnly ? resolvedMomSubtitle : resolvedMidwifeSubtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.45))
        }
    }

    // MARK: - Empty / list

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(model.accentColor)

            Text(mode == .momReadOnly ? model.emptyMomMessage : model.emptyMidwifeMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .padding(.horizontal, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }

    private var notesList: some View {
        VStack(spacing: 12) {
            ForEach(notes) { note in
                noteCard(note)
            }
        }
    }

    private func noteCard(_ note: MomJournalNote) -> some View {
        let canEdit = (mode == .midwifeEntry) && (session?.userId == note.createdByUserId)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(model.accentColor.opacity(0.14))
                        .frame(width: 32, height: 32)
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(model.accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(note.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(deepMaroon)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(displayDate(iso: note.updatedAt ?? note.createdAt))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.42))
                }

                Spacer()

                Text(authorBadge(for: note))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(badgeColor(for: note))
                    .clipShape(Capsule())
            }

            if !note.body.isEmpty {
                Text(note.body)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.black.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if canEdit {
                HStack(spacing: 10) {
                    Spacer()

                    Button {
                        editingNote = note
                        titleText = note.title
                        bodyText = note.body
                        showEditor = true
                    } label: {
                        Text("Edit")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(model.accentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(model.accentColor.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        pendingDelete = note
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.red.opacity(0.85))
                            .padding(7)
                            .background(Color.red.opacity(0.10))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }

    // MARK: - Add button + editor

    private var addNoteButton: some View {
        Button {
            editingNote = nil
            titleText = ""
            bodyText = ""
            showEditor = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                Text(model.addButtonTitle)
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(model.accentColor)
            .clipShape(Capsule())
            .shadow(color: model.accentColor.opacity(0.35), radius: 12, y: 6)
        }
        .disabled(session == nil || momUserId == nil || isSaving)
        .opacity((session == nil || momUserId == nil) ? 0.5 : 1.0)
    }

    private var editorSheet: some View {
        NavigationStack {
            ZStack {
                model.backgroundColor.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Title")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.black.opacity(0.55))

                        TextField(model.titlePlaceholder, text: $titleText)
                            .font(.system(size: 15, weight: .medium))
                            .padding(14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        Text("Body")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.black.opacity(0.55))
                            .padding(.top, 4)

                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $bodyText)
                                .font(.system(size: 15))
                                .frame(minHeight: 220)
                                .padding(8)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            if bodyText.isEmpty {
                                Text(model.bodyPlaceholder)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.black.opacity(0.30))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 16)
                                    .allowsHitTesting(false)
                            }
                        }

                        Button {
                            Task { await saveNote() }
                        } label: {
                            HStack(spacing: 8) {
                                if isSaving {
                                    ProgressView().tint(.white)
                                }
                                Text(isSaving ? "Saving..." : model.saveButtonTitle)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(model.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .disabled(isSaving || titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .padding(.top, 10)
                    }
                    .padding(18)
                }
            }
            .navigationTitle(editingNote == nil ? "New note" : "Edit note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showEditor = false }
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Networking

    @MainActor
    private func reload() async {
        guard let session, let momUserId else {
            notes = []
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            notes = try await MomJournalNotesRepository().fetchNotes(
                momUserId: momUserId,
                childId: childId,
                accessToken: session.accessToken
            )
        } catch SupabaseServiceError.httpError(let status, let body) {
            errorMessage = "Could not load notes (\(status)): \(SupabaseAuthService.humanMessage(fromBody: body))"
            notes = []
        } catch {
            errorMessage = "Could not load notes: \(error.localizedDescription)"
            notes = []
        }
    }

    @MainActor
    private func saveNote() async {
        guard let session, let momUserId else { return }
        let trimmedTitle = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        let trimmedBody = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)

        isSaving = true
        defer { isSaving = false }

        do {
            if let editing = editingNote {
                try await MomJournalNotesRepository().updateNote(
                    noteId: editing.id,
                    title: trimmedTitle,
                    body: trimmedBody,
                    accessToken: session.accessToken
                )
            } else {
                try await MomJournalNotesRepository().insertNote(
                    momUserId: momUserId,
                    createdByUserId: session.userId,
                    authorRole: mode == .midwifeEntry ? "midwife" : "mom",
                    childId: childId,
                    title: trimmedTitle,
                    body: trimmedBody,
                    accessToken: session.accessToken
                )
            }
            showEditor = false
            await reload()
        } catch SupabaseServiceError.httpError(let status, let body) {
            errorMessage = "Save failed (\(status)): \(SupabaseAuthService.humanMessage(fromBody: body))"
        } catch {
            errorMessage = "Save failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func deleteNote(_ note: MomJournalNote) async {
        guard let session else { return }
        do {
            try await MomJournalNotesRepository().deleteNote(
                noteId: note.id,
                accessToken: session.accessToken
            )
            await reload()
        } catch SupabaseServiceError.httpError(let status, let body) {
            errorMessage = "Delete failed (\(status)): \(SupabaseAuthService.humanMessage(fromBody: body))"
        } catch {
            errorMessage = "Delete failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Helpers

    private func resetEditingState() {
        editingNote = nil
        titleText = ""
        bodyText = ""
    }

    private func badgeColor(for note: MomJournalNote) -> Color {
        switch note.authorRole {
        case "midwife": return Color(red: 0.55, green: 0.35, blue: 0.75)
        case "admin":   return Color.black.opacity(0.6)
        default:        return model.accentColor
        }
    }

    private func authorBadge(for note: MomJournalNote) -> String {
        switch note.authorRole {
        case "midwife": return "MIDWIFE"
        case "admin":   return "ADMIN"
        default:        return "MOM"
        }
    }

    /// Postgres returns timestamps in the form `2026-05-07T08:23:14.123456+00:00`.
    /// We display a friendly "MMM d, yyyy" date prefix only.
    private func displayDate(iso: String?) -> String {
        guard let iso, iso.count >= 10 else { return "" }
        let datePart = String(iso.prefix(10))
        let inDf = DateFormatter()
        inDf.locale = Locale(identifier: "en_US_POSIX")
        inDf.dateFormat = "yyyy-MM-dd"
        guard let d = inDf.date(from: datePart) else { return iso }
        let out = DateFormatter()
        out.dateStyle = .medium
        out.timeStyle = .none
        return out.string(from: d)
    }
}

#Preview {
    NavigationStack {
        MomJournalNotesView(
            model: MomJournalNotesController().loadModel(),
            session: AuthSessionContext(userId: UUID(), accessToken: "preview"),
            momUserId: UUID(),
            mode: .midwifeEntry
        )
    }
}
