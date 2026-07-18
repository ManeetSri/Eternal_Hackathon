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

struct MealSearchWidgetEntryView: View {
    var entry: MealSearchWidgetProvider.Entry

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar (top)
            HStack(spacing: 12) {
                // Logo/Icon
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.yellow)

                Text("Meal")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.yellow)

                Spacer()

                // Search Icon
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.25, green: 0.25, blue: 0.25))
            )
            .padding(16)

            // Search Text (center)
            Spacer()

            VStack(alignment: .leading, spacing: 6) {
                Text("Search")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                Text("Meal to Cart")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)

            Spacer()

            // Action Button (bottom)
            Link(destination: URL(string: "eternalscan://meal?autoReturn=true")!) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))

                    Text("Describe a Meal")
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.white)
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                .cornerRadius(12)
            }
            .padding(16)
        }
        .containerBackground(
            for: .widget,
            content: {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.15, green: 0.15, blue: 0.15),
                        Color(red: 0.1, green: 0.1, blue: 0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
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
        .configurationDisplayName("Meal to Cart")
        .description("Describe a meal and add ingredients to cart")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    MealSearchWidget()
} timeline: {
    MealSearchWidgetEntry(date: .now)
}
