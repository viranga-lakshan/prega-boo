import SwiftUI
import WidgetKit

// MARK: - Snapshot model (mirrors WidgetSnapshotStore in the main app)

struct MomWidgetSnapshot: Codable {
    let momName: String
    let district: String
    let babyCount: Int
    let nextReminderTitle: String?
    let nextReminderWhen: String?
    let trackerMessage: String
    let updatedAtISO: String

    enum CodingKeys: String, CodingKey {
        case momName, district, babyCount, nextReminderTitle, nextReminderWhen, trackerMessage, updatedAtISO
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        momName = try container.decode(String.self, forKey: .momName)
        district = try container.decode(String.self, forKey: .district)
        babyCount = try container.decodeIfPresent(Int.self, forKey: .babyCount) ?? 0
        nextReminderTitle = try container.decodeIfPresent(String.self, forKey: .nextReminderTitle)
        nextReminderWhen = try container.decodeIfPresent(String.self, forKey: .nextReminderWhen)
        trackerMessage = try container.decode(String.self, forKey: .trackerMessage)
        updatedAtISO = try container.decode(String.self, forKey: .updatedAtISO)
    }
}

private enum WidgetSnapshotReader {
    static let appGroupId = "group.cw.prega-boo"
    static let key = "mom.widget.snapshot.v1"
    static let deepLinkURL = URL(string: "cw.prega-boo://widget-nav/mom-baby-details")!

    static func load() -> MomWidgetSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(MomWidgetSnapshot.self, from: data) else {
            return nil
        }
        return decoded
    }
}

// MARK: - Brand palette

private enum WidgetBrand {
    static let pink = Color(red: 0.94, green: 0.39, blue: 0.45)
    static let pinkSoft = Color(red: 0.99, green: 0.92, blue: 0.94)
    static let ink = Color.black.opacity(0.78)
    static let muted = Color.black.opacity(0.55)
}

// MARK: - Timeline

struct PregaBooWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: MomWidgetSnapshot?
}

struct PregaBooProvider: TimelineProvider {
    func placeholder(in context: Context) -> PregaBooWidgetEntry {
        PregaBooWidgetEntry(date: Date(), snapshot: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (PregaBooWidgetEntry) -> Void) {
        completion(PregaBooWidgetEntry(date: Date(), snapshot: WidgetSnapshotReader.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PregaBooWidgetEntry>) -> Void) {
        let entry = PregaBooWidgetEntry(date: Date(), snapshot: WidgetSnapshotReader.load())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Widget definition

struct PregaBooWidget: Widget {
    let kind: String = "PregaBooWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PregaBooProvider()) { entry in
            PregaBooWidgetEntryView(entry: entry)
                .widgetURL(WidgetSnapshotReader.deepLinkURL)
        }
        .configurationDisplayName("Mom & Baby Details")
        .description("Quick mom summary with the next clinic or vaccine reminder.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Views

private struct PregaBooWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PregaBooWidgetEntry

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                MediumWidgetView(snapshot: entry.snapshot)
            default:
                SmallWidgetView(snapshot: entry.snapshot)
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [WidgetBrand.pinkSoft, .white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private struct SmallWidgetView: View {
    let snapshot: MomWidgetSnapshot?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(WidgetBrand.pink)
                Text("Prega Boo")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetBrand.pink)
            }

            if let snap = snapshot {
                Text("Hi, \(snap.momName)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetBrand.ink)
                    .lineLimit(1)
                Text(headerLine(for: snap))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WidgetBrand.muted)
                    .lineLimit(1)

                if let title = snap.nextReminderTitle, let when = snap.nextReminderWhen {
                    Spacer(minLength: 4)
                    NextReminderCompact(title: title, when: when)
                } else {
                    Spacer(minLength: 0)
                    BabyCountChip(count: snap.babyCount)
                }

                HStack(spacing: 4) {
                    Text("Mom & Baby")
                        .font(.system(size: 11, weight: .bold))
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(WidgetBrand.pink)
            } else {
                EmptySnapshotView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func headerLine(for snap: MomWidgetSnapshot) -> String {
        let babies = snap.babyCount == 1 ? "1 baby" : "\(snap.babyCount) babies"
        return "\(snap.district) • \(babies)"
    }
}

private struct MediumWidgetView: View {
    let snapshot: MomWidgetSnapshot?

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(WidgetBrand.pink)
                    Text("Prega Boo")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetBrand.pink)
                }

                if let snap = snapshot {
                    Text("Hi, \(snap.momName)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetBrand.ink)
                        .lineLimit(1)
                    Text(headerLine(for: snap))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(WidgetBrand.muted)
                        .lineLimit(1)

                    Spacer(minLength: 6)

                    if let title = snap.nextReminderTitle, let when = snap.nextReminderWhen {
                        NextReminderBlock(title: title, when: when)
                    } else {
                        Text("No upcoming reminders.")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(WidgetBrand.muted)
                    }

                    Spacer(minLength: 6)

                    HStack(spacing: 6) {
                        Text("Tap to open Mom & Baby Details")
                            .font(.system(size: 11, weight: .bold))
                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(WidgetBrand.pink)
                } else {
                    EmptySnapshotView()
                }
            }

            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(WidgetBrand.pink.opacity(0.15))
                    .frame(width: 60, height: 60)
                Image(systemName: "figure.and.child.holdinghands")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(WidgetBrand.pink)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func headerLine(for snap: MomWidgetSnapshot) -> String {
        let babies = snap.babyCount == 1 ? "1 baby" : "\(snap.babyCount) babies"
        return "\(snap.district) • \(babies)"
    }
}

private struct NextReminderBlock: View {
    let title: String
    let when: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 10, weight: .bold))
                Text("Next Reminder")
                    .font(.system(size: 10, weight: .bold))
                    .textCase(.uppercase)
            }
            .foregroundStyle(WidgetBrand.pink)

            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(WidgetBrand.ink)
                .lineLimit(1)
            Text(when)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(WidgetBrand.muted)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WidgetBrand.pink.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct NextReminderCompact: View {
    let title: String
    let when: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 3) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 8, weight: .bold))
                Text("Next")
                    .font(.system(size: 9, weight: .bold))
                    .textCase(.uppercase)
            }
            .foregroundStyle(WidgetBrand.pink)
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(WidgetBrand.ink)
                .lineLimit(1)
            Text(when)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(WidgetBrand.muted)
                .lineLimit(1)
        }
    }
}

private struct BabyCountChip: View {
    let count: Int

    private var label: String {
        switch count {
        case 0: return "No baby yet"
        case 1: return "1 baby"
        default: return "\(count) babies"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "figure.2.and.child.holdinghands")
                .font(.system(size: 9, weight: .bold))
            Text(label)
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(WidgetBrand.pink)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(WidgetBrand.pink.opacity(0.12), in: Capsule())
    }
}

private struct EmptySnapshotView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sign in to your mom profile")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(WidgetBrand.ink)
            Text("Open Prega Boo once so the widget can show your details.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(WidgetBrand.muted)
                .lineLimit(3)
        }
    }
}
