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
        ZStack {
            // Premium gradient background (AI vibe)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.05, blue: 0.2), // Dark Purple
                    Color(red: 0.05, green: 0.1, blue: 0.2)  // Dark Blue
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle glowing orb effect
            Circle()
                .fill(Color.purple.opacity(0.3))
                .blur(radius: 40)
                .frame(width: 150, height: 150)
                .offset(x: -40, y: -40)

            Circle()
                .fill(Color.blue.opacity(0.3))
                .blur(radius: 40)
                .frame(width: 150, height: 150)
                .offset(x: 40, y: 40)

            VStack(spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text("AI Meal")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer()

                // Main Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Craving")
                        .font(.system(size: 24, weight: .light, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Something?")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

                Spacer()

                // Call to Action Button
                Link(destination: URL(string: "eternalscan://meal?autoReturn=true")!) {
                    HStack(spacing: 8) {
                        Text("Describe your meal")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 14))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .containerBackground(for: .widget) {
            Color.black
        }
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
        .configurationDisplayName("AI Meal Assistant")
        .description("Instantly turn any meal idea into a shopping cart.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    MealSearchWidget()
} timeline: {
    MealSearchWidgetEntry(date: .now)
}
