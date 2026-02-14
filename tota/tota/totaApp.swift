import SwiftUI

@main
struct totaApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Practice", systemImage: "mic.fill") {
                    PracticeTab()
                }
                Tab("Learn", systemImage: "book.fill") {
                    placeholderTab(icon: "book.fill", title: "Learn")
                }
                Tab("Today", systemImage: "calendar") {
                    placeholderTab(icon: "calendar", title: "Today")
                }
                Tab("Stats", systemImage: "chart.bar.fill") {
                    placeholderTab(icon: "chart.bar.fill", title: "Stats")
                }
            }
            .tint(Theme.brand)
        }
    }

    private func placeholderTab(icon: String, title: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.tertiary)
            Text("Coming Soon")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
