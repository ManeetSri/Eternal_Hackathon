//
//  MealSearchWidget.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

import WidgetKit
import SwiftUI

struct MealSearchWidgetEntry: TimelineEntry {
    let date: Date
}

struct MealSearchWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MealSearchWidgetEntry {
        MealSearchWidgetEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (MealSearchWidgetEntry) -> ()) {
        completion(MealSearchWidgetEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let timeline = Timeline(entries: [MealSearchWidgetEntry(date: Date())], policy: .never)
        completion(timeline)
    }
}

private struct WidgetRecipeChip: Identifiable {
    let id: String
    let title: String

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

struct MealSearchWidgetEntryView: View {
    var entry: MealSearchWidgetProvider.Entry
    @Environment(\.widgetFamily) private var family

    private static let deepLink = URL(string: "eternalscan://meal?autoReturn=true")!

    private static let recipeChips: [WidgetRecipeChip] = [
        WidgetRecipeChip(id: "pasta", title: "Pasta"),
        WidgetRecipeChip(id: "maggi", title: "Maggi"),
        WidgetRecipeChip(id: "omelette", title: "Omelette"),
    ]

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                mediumLayout
            default:
                smallLayout
            }
        }
        .widgetURL(Self.deepLink)
        .containerBackground(for: .widget) {
            ESColor.surface
        }
    }

    // MARK: - Layouts

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            sparklesBadge

            Spacer(minLength: 0)

            (Text("Describe\n").foregroundStyle(ESColor.foreground)
             + Text("a meal.").foregroundStyle(ESColor.ai))
                .font(ESFont.sans(21, weight: .heavy))
                .tracking(-0.8)
                .lineSpacing(-3)

            fauxInputRow(placeholder: "PASTA FOR 4")
                .padding(.top, 9)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var mediumLayout: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    sparklesBadge
                    (Text("Describe ").foregroundStyle(ESColor.foreground)
                     + Text("a meal.").foregroundStyle(ESColor.ai))
                        .font(ESFont.sans(17, weight: .heavy))
                        .tracking(-0.5)
                }

                Spacer(minLength: 8)

                Text("Turn any craving into a cart")
                    .monoLabel(size: 9)
                    .padding(.bottom, 8)

                fauxInputRow(placeholder: "PASTA ARRABBIATA FOR 4")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Text("Try").monoLabel(size: 9)
                ForEach(Self.recipeChips) { chip in
                    Link(destination: chip.deepLink) {
                        HStack(spacing: 4) {
                            Text(chip.title.uppercased())
                                .font(ESFont.mono(10, weight: .bold))
                                .kerning(1.2)
                                .foregroundStyle(ESColor.foreground)
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
                }
            }
            .frame(width: 116)
        }
    }

    // MARK: - Components

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
        .description("Turn any meal idea into a shopping cart")
        .supportedFamilies([.systemSmall, .systemMedium])
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
