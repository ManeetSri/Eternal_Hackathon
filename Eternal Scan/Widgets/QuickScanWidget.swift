//
//  QuickScanWidget.swift
//  Eternal Scan Widget
//

import WidgetKit
import SwiftUI

// MARK: - Quick Scan Entry
struct QuickScanEntry: TimelineEntry {
    let date: Date
    let lastScannedProduct: String?
    let lastScanTime: Date?
}

// MARK: - Quick Scan Provider
struct QuickScanProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickScanEntry {
        QuickScanEntry(
            date: Date(),
            lastScannedProduct: "Coca-Cola Classic",
            lastScanTime: Date()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickScanEntry) -> ()) {
        let entry = QuickScanEntry(
            date: Date(),
            lastScannedProduct: nil,
            lastScanTime: nil
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [QuickScanEntry] = []
        let currentDate = Date()

        for hourOffset in 0..<4 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = QuickScanEntry(
                date: entryDate,
                lastScannedProduct: nil,
                lastScanTime: nil
            )
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Small Widget View
struct QuickScanSmallView: View {
    var entry: QuickScanProvider.Entry

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.6, blue: 0.8),
                    Color(red: 0.15, green: 0.5, blue: 0.75)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 12) {
                Link(destination: URL(string: "eternalscan://scan?flash=false&autoReturn=true")!) {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)

                        Text("Scan")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(12)
        }
    }
}

// MARK: - Medium Widget View
struct QuickScanMediumView: View {
    var entry: QuickScanProvider.Entry

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.6, blue: 0.8),
                    Color(red: 0.15, green: 0.5, blue: 0.75)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scan Product")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)

                        Text("Quick product search")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.6))
                }

                Divider()
                    .background(Color.white.opacity(0.3))

                Link(destination: URL(string: "eternalscan://scan?flash=false&autoReturn=true")!) {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Open Camera")
                                .font(.system(size: 14, weight: .semibold))

                            Text("Start scanning")
                                .font(.system(size: 11))
                                .opacity(0.8)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                }

                if let lastProduct = entry.lastScannedProduct, let lastTime = entry.lastScanTime {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last Scanned")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))

                        Text(lastProduct)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)

                        Text(lastTime, style: .relative)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(6)
                }

                Spacer()
            }
            .padding(16)
        }
    }
}

// MARK: - Widget Entry View
struct QuickScanEntryView: View {
    var entry: QuickScanProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            QuickScanSmallView(entry: entry)
        case .systemMedium:
            QuickScanMediumView(entry: entry)
        default:
            QuickScanMediumView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration
struct QuickScanWidget: Widget {
    let kind: String = "QuickScanWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: QuickScanProvider()
        ) { entry in
            QuickScanEntryView(entry: entry)
        }
        .configurationDisplayName("Quick Scan")
        .description("Tap to open camera and start scanning products")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview
#Preview(as: .systemMedium) {
    QuickScanWidget()
} timeline: {
    QuickScanEntry(
        date: .now,
        lastScannedProduct: "Coca-Cola Classic",
        lastScanTime: Date(timeIntervalSinceNow: -300)
    )
}
