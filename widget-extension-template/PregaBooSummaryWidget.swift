import SwiftUI
import WidgetKit

private struct MomWidgetSnapshot: Codable {
    let momName: String
    let district: String
    let trackerMessage: String
    let updatedAtISO: String
}

private enum WidgetSnapshotReader {
    static let appGroupId = "group.cw.prega-boo"
    static let key = "mom.widget.snapshot.v1"

    static func load() -> MomWidgetSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(MomWidgetSnapshot.self, from: data) else {
            return nil
        }
        return decoded
    }
}

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

struct PregaBooSummaryWidget: Widget {
    let kind: String = "PregaBooSummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PregaBooProvider()) { entry in
            PregaBooSummaryWidgetView(entry: entry)
        }
        .configurationDisplayName("Prega Boo Summary")
        .description("Quick mom summary and tracker reminder.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct PregaBooSummaryWidgetView: View {
    let entry: PregaBooWidgetEntry

    var body: some View {
        if let snap = entry.snapshot {
            VStack(alignment: .leading, spacing: 6) {
                Text("Prega Boo")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.pink)
                Text(snap.momName)
                    .font(.system(size: 18, weight: .bold))
                    .lineLimit(1)
                Text(snap.district)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text(snap.trackerMessage)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            .padding()
            .containerBackground(.background, for: .widget)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("Prega Boo")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.pink)
                Text("Open app once")
                    .font(.system(size: 16, weight: .bold))
                Text("Widget content appears after dashboard loads.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
            .containerBackground(.background, for: .widget)
        }
    }
}
