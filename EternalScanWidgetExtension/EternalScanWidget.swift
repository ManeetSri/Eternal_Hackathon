//
//  EternalScanWidget.swift
//  EternalScanWidgetExtension
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct EternalScanWidgetEntry: TimelineEntry {
    let date: Date
}

// MARK: - Widget Provider
struct EternalScanWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> EternalScanWidgetEntry {
        EternalScanWidgetEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (EternalScanWidgetEntry) -> ()) {
        let entry = EternalScanWidgetEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [EternalScanWidgetEntry] = []
        let currentDate = Date()

        for hourOffset in 0..<12 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = EternalScanWidgetEntry(date: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Widget View
struct EternalScanWidgetEntryView: View {
    var entry: EternalScanWidgetProvider.Entry

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.6, blue: 0.8),
                    Color(red: 0.1, green: 0.4, blue: 0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 16) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 40))
                    .foregroundColor(.white)

                Text("Eternal Scan")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text("Tap to scan")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                Link(destination: URL(string: "eternalscan://scan?flash=false&autoReturn=true")!) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16))

                        Text("Open Camera")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.white)
                    .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.8))
                    .cornerRadius(8)
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Widget Configuration
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
        .description("Quick access to scan products with your camera")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    EternalScanWidget()
} timeline: {
    EternalScanWidgetEntry(date: .now)
}
