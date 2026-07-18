//
//  SpeakToOrderWidget.swift
//  Eternal Scan — one tap into voice ordering, from Home or Lock Screen.
//

import WidgetKit
import SwiftUI

struct SpeakToOrderWidgetEntry: TimelineEntry {
    let date: Date
}

struct SpeakToOrderWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SpeakToOrderWidgetEntry {
        SpeakToOrderWidgetEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SpeakToOrderWidgetEntry) -> ()) {
        completion(SpeakToOrderWidgetEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        completion(Timeline(entries: [SpeakToOrderWidgetEntry(date: Date())], policy: .never))
    }
}

struct SpeakToOrderWidgetEntryView: View {
    var entry: SpeakToOrderWidgetProvider.Entry
    @Environment(\.widgetFamily) private var family

    private static let deepLink = URL(string: "eternalscan://voice")!
    private static let mealDeepLink = URL(string: "eternalscan://meal?autoReturn=true")!

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                mediumLayout
            case .accessoryCircular:
                accessoryCircularLayout
            case .accessoryRectangular:
                accessoryRectangularLayout
            default:
                smallLayout
            }
        }
        .widgetURL(Self.deepLink)
        .containerBackground(for: .widget) {
            switch family {
            case .accessoryCircular, .accessoryRectangular:
                Color.clear
            default:
                ESColor.primary
            }
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }

            Spacer(minLength: 0)

            Text("Speak your\norder.")
                .font(ESFont.sans(23, weight: .heavy))
                .tracking(-1.0)
                .lineSpacing(-3)
                .foregroundStyle(.white)

            HStack(spacing: 5) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 4, height: 4)
                Text("No typing needed")
                    .monoLabel(size: 9, color: .white.opacity(0.75))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.top, 7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Speak your order. Opens voice ordering.")
    }

    private var mediumLayout: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Spacer(minLength: 0)

                Text("Speak your order.")
                    .font(ESFont.sans(21, weight: .heavy))
                    .tracking(-0.8)
                    .foregroundStyle(.white)

                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 4, height: 4)
                    Text("No typing needed")
                        .monoLabel(size: 9, color: .white.opacity(0.75))
                }
                .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Speak your order. Opens voice ordering.")

            // Cross-link back to typed meal search
            Link(destination: Self.mealDeepLink) {
                VStack(spacing: 8) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Type\ninstead")
                        .font(ESFont.mono(9, weight: .bold))
                        .kerning(1.0)
                        .textCase(.uppercase)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.white.opacity(0.85))
                }
                .frame(width: 76)
                .frame(maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                )
            }
            .accessibilityLabel("Type a meal instead. Opens meal search.")
        }
    }

    private var accessoryCircularLayout: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "mic.fill")
                .font(.system(size: 20, weight: .semibold))
        }
        .accessibilityLabel("Speak your order. Opens voice ordering.")
    }

    private var accessoryRectangularLayout: some View {
        HStack(spacing: 8) {
            Image(systemName: "mic.fill")
                .font(.system(size: 16, weight: .semibold))
            VStack(alignment: .leading, spacing: 1) {
                Text("Speak your order")
                    .font(.system(size: 14, weight: .bold))
                Text("Groceries, no typing")
                    .font(.system(size: 12, weight: .medium))
                    .opacity(0.7)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Speak your order. Opens voice ordering.")
    }
}

struct SpeakToOrderWidget: Widget {
    let kind: String = "SpeakToOrderWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: SpeakToOrderWidgetProvider()
        ) { entry in
            SpeakToOrderWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Speak to Order")
        .description("Say what you want to eat — no typing, no searching.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

#Preview(as: .systemSmall) {
    SpeakToOrderWidget()
} timeline: {
    SpeakToOrderWidgetEntry(date: .now)
}

#Preview(as: .systemMedium) {
    SpeakToOrderWidget()
} timeline: {
    SpeakToOrderWidgetEntry(date: .now)
}
