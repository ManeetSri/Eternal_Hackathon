import WidgetKit
import SwiftUI

struct EternalScanWidgetEntry: TimelineEntry {
    let date: Date
}

struct EternalScanWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> EternalScanWidgetEntry {
        EternalScanWidgetEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (EternalScanWidgetEntry) -> ()) {
        completion(EternalScanWidgetEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let timeline = Timeline(entries: [EternalScanWidgetEntry(date: Date())], policy: .never)
        completion(timeline)
    }
}

struct EternalScanWidgetEntryView: View {
    var entry: EternalScanWidgetProvider.Entry

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 32))
                .foregroundColor(.white)

            Text("Eternal Scan")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Link(destination: URL(string: "eternalscan://scan?autoReturn=true")!) {
                HStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14))
                    Text("Tap to Scan")
                        .font(.system(size: 13, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color.white)
                .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.8))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .containerBackground(
            for: .widget,
            content: {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.2, green: 0.6, blue: 0.8),
                        Color(red: 0.1, green: 0.4, blue: 0.7)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
    }
}

struct EternalScanWidget: Widget {
    let kind: String = "EternalScanWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: EternalScanWidgetProvider()
        ) { entry in
            EternalScanWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Eternal Scan")
        .description("Quickly scan products with your camera")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    EternalScanWidget()
} timeline: {
    EternalScanWidgetEntry(date: .now)
}
