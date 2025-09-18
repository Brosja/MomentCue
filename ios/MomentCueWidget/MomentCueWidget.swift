import WidgetKit
import SwiftUI

struct MomentCueWidget: Widget {
    let kind: String = "MomentCueWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MomentCueWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("MomentCue")
        .description("Quick access to your health check-ins")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), checks: [
            CheckItem(id: "1", title: "Water", completed: false),
            CheckItem(id: "2", title: "Exercise", completed: true),
            CheckItem(id: "3", title: "Meditation", completed: false)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), checks: [
            CheckItem(id: "1", title: "Water", completed: false),
            CheckItem(id: "2", title: "Exercise", completed: true),
            CheckItem(id: "3", title: "Meditation", completed: false)
        ])
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, checks: [
            CheckItem(id: "1", title: "Water", completed: false),
            CheckItem(id: "2", title: "Exercise", completed: true),
            CheckItem(id: "3", title: "Meditation", completed: false)
        ])
        
        let nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let checks: [CheckItem]
}

struct CheckItem: Identifiable {
    let id: String
    let title: String
    let completed: Bool
}

struct MomentCueWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("MomentCue")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text(entry.date, style: .time)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Quick checks
            VStack(alignment: .leading, spacing: 4) {
                ForEach(entry.checks) { check in
                    HStack {
                        Image(systemName: check.completed ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(check.completed ? .green : .white.opacity(0.6))
                        Text(check.title)
                            .font(.caption)
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
            }
            
            Spacer()
            
            // Open app button
            HStack {
                Spacer()
                Text("Open App")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.red.opacity(0.8), Color.pink.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

@main
struct MomentCueWidgetBundle: WidgetBundle {
    var body: some Widget {
        MomentCueWidget()
    }
}
