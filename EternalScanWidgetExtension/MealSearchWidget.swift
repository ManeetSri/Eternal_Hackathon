//
//  MealSearchWidget.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

import WidgetKit
import SwiftUI

// MARK: - Daypart

/// Meal-time context. Suggestions rotate with the clock so the widget
/// always proposes something plausible to cook right now.
enum Daypart {
    case morning, afternoon, evening, lateNight

    init(date: Date) {
        switch Calendar.current.component(.hour, from: date) {
        case 5..<11: self = .morning
        case 11..<16: self = .afternoon
        case 16..<22: self = .evening
        default: self = .lateNight
        }
    }

    /// Hours at which the widget content should roll over.
    static let boundaryHours = [5, 11, 16, 22]

    var tryLabel: String {
        switch self {
        case .morning: return "This morning"
        case .afternoon: return "For lunch"
        case .evening: return "For dinner"
        case .lateNight: return "Late night"
        }
    }

    var placeholder: String {
        switch self {
        case .morning: return "OMELETTE FOR 2"
        case .afternoon: return "PASTA FOR 4"
        case .evening: return "RAJMA CHAWAL FOR 4"
        case .lateNight: return "MAGGI FOR 1"
        }
    }

    // Chip titles double as search queries; each tokenizes onto the
    // repository's recipe keys (pasta/maggi/omelette/tea/salad/rajma/chawal).
    var chips: [WidgetRecipeChip] {
        switch self {
        case .morning:
            return [WidgetRecipeChip("Omelette"), WidgetRecipeChip("Ginger Tea"), WidgetRecipeChip("Maggi")]
        case .afternoon:
            return [WidgetRecipeChip("Pasta"), WidgetRecipeChip("Salad"), WidgetRecipeChip("Rajma Chawal")]
        case .evening:
            return [WidgetRecipeChip("Rajma Chawal"), WidgetRecipeChip("Pasta"), WidgetRecipeChip("Maggi")]
        case .lateNight:
            return [WidgetRecipeChip("Maggi"), WidgetRecipeChip("Omelette"), WidgetRecipeChip("Ginger Tea")]
        }
    }
}

struct WidgetRecipeChip: Identifiable {
    let title: String
    var id: String { title }

    init(_ title: String) {
        self.title = title
    }

    var deepLink: URL {
        var components = URLComponents()
        components.scheme = "eternalscan"
        components.host = "meal"
        components.queryItems = [
            URLQueryItem(name: "query", value: title),
            URLQueryItem(name: "autoReturn", value: "true"),
        ]
        return components.url!
    }
}

// MARK: - Timeline

struct MealSearchWidgetEntry: TimelineEntry {
    let date: Date

    var daypart: Daypart { Daypart(date: date) }
}

struct MealSearchWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MealSearchWidgetEntry {
        MealSearchWidgetEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (MealSearchWidgetEntry) -> ()) {
        completion(MealSearchWidgetEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // One entry now, plus one at each upcoming meal boundary in the
        // next 24h, so suggestions follow breakfast/lunch/dinner.
        let now = Date()
        var entries = [MealSearchWidgetEntry(date: now)]
        for hour in Daypart.boundaryHours {
            if let next = Calendar.current.nextDate(
                after: now,
                matching: DateComponents(hour: hour, minute: 0),
                matchingPolicy: .nextTime
            ) {
                entries.append(MealSearchWidgetEntry(date: next))
            }
        }
        entries.sort { $0.date < $1.date }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Views

struct MealSearchWidgetEntryView: View {
    var entry: MealSearchWidgetProvider.Entry
    @Environment(\.widgetFamily) private var family

    private static let deepLink = URL(string: "eternalscan://meal?autoReturn=true")!

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
                ESColor.surface
            }
        }
    }

    // MARK: Home screen

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            sparklesBadge

            Spacer(minLength: 0)

            Text("Describe\n\(Text("a meal.").foregroundStyle(ESColor.ai))")
                .foregroundStyle(ESColor.foreground)
                .font(ESFont.sans(21, weight: .heavy))
                .tracking(-0.8)
                .lineSpacing(-3)

            fauxInputRow(placeholder: entry.daypart.placeholder)
                .padding(.top, 9)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Describe a meal. Opens meal search, for example \(entry.daypart.placeholder.capitalized).")
    }

    private var mediumLayout: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    sparklesBadge
                    Text("Describe \(Text("a meal.").foregroundStyle(ESColor.ai))")
                        .foregroundStyle(ESColor.foreground)
                        .font(ESFont.sans(17, weight: .heavy))
                        .tracking(-0.5)
                }

                Spacer(minLength: 8)

                Text("Turn any craving into a cart")
                    .monoLabel(size: 9)
                    .padding(.bottom, 8)

                fauxInputRow(placeholder: entry.daypart.placeholder)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Describe a meal. Opens meal search.")

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.daypart.tryLabel).monoLabel(size: 9)
                ForEach(entry.daypart.chips) { chip in
                    Link(destination: chip.deepLink) {
                        HStack(spacing: 4) {
                            Text(chip.title.uppercased())
                                .font(ESFont.mono(10, weight: .bold))
                                .kerning(1.2)
                                .foregroundStyle(ESColor.foreground)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(ESColor.muted)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(ESColor.chip)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(ESColor.border, lineWidth: 1)
                                )
                        )
                    }
                    .accessibilityLabel("Search \(chip.title)")
                }
            }
            .frame(width: 116)
        }
    }

    // MARK: Lock screen

    private var accessoryCircularLayout: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .semibold))
        }
        .accessibilityLabel("Describe a meal. Opens meal search.")
    }

    private var accessoryRectangularLayout: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .semibold))
            VStack(alignment: .leading, spacing: 1) {
                Text("Describe a meal")
                    .font(.system(size: 14, weight: .bold))
                Text(entry.daypart.placeholder.capitalized)
                    .font(.system(size: 12, weight: .medium))
                    .opacity(0.7)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Describe a meal. Opens meal search, for example \(entry.daypart.placeholder.capitalized).")
    }

    // MARK: Components

    private var sparklesBadge: some View {
        Image(systemName: "sparkles")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(ESColor.ai)
            )
            .accessibilityHidden(true)
    }

    private func fauxInputRow(placeholder: String) -> some View {
        HStack(spacing: 6) {
            Text(placeholder)
                .font(ESFont.mono(10, weight: .bold))
                .kerning(1.0)
                .foregroundStyle(ESColor.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            Image(systemName: "arrow.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(ESColor.foreground))
        }
        .padding(.leading, 12)
        .padding(.trailing, 5)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(ESColor.chip)
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(ESColor.border, lineWidth: 1)
                )
        )
    }
}

struct MealSearchWidget: Widget {
    let kind: String = "MealSearchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: MealSearchWidgetProvider()
        ) { entry in
            MealSearchWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Describe a Meal")
        .description("Meal ideas that follow the clock — turn any craving into a cart.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

#Preview(as: .systemSmall) {
    MealSearchWidget()
} timeline: {
    MealSearchWidgetEntry(date: .now)
}

#Preview(as: .systemMedium) {
    MealSearchWidget()
} timeline: {
    MealSearchWidgetEntry(date: .now)
}

#Preview(as: .accessoryRectangular) {
    MealSearchWidget()
} timeline: {
    MealSearchWidgetEntry(date: .now)
}
