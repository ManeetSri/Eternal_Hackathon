//
//  EternalScanWidget.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

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

    private static let deepLink = URL(string: "eternalscan://scan?autoReturn=true")!

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                cameraBadge
            }

            Spacer(minLength: 0)

            Text("Snap to\n\(Text("reorder.").foregroundStyle(ESColor.primary))")
                .foregroundStyle(.white)
                .font(ESFont.sans(23, weight: .heavy))
                .tracking(-1.0)
                .lineSpacing(-3)

            HStack(spacing: 5) {
                Circle()
                    .fill(ESColor.primary)
                    .frame(width: 4, height: 4)
                Text("ReSnap packaging")
                    .monoLabel(size: 9, color: .white.opacity(0.65))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.top, 7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(Self.deepLink)
        .containerBackground(for: .widget) {
            ESColor.foreground
        }
    }

    private var cameraBadge: some View {
        ZStack {
            Image(systemName: "viewfinder")
                .font(.system(size: 38, weight: .thin))
                .foregroundStyle(ESColor.primary)
            Image(systemName: "camera.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
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
        .configurationDisplayName("ReSnap")
        .description("Point at empty packaging — your reorder builds itself.")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    EternalScanWidget()
} timeline: {
    EternalScanWidgetEntry(date: .now)
}
