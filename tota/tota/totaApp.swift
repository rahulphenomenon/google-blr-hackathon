import SwiftUI

@main
struct totaApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("practice", systemImage: "mic.fill") {
                    PracticeTab()
                }
                Tab("learn", systemImage: "book.fill") {
                    Text("coming soon")
                }
                Tab("today", systemImage: "calendar") {
                    Text("coming soon")
                }
                Tab("stats", systemImage: "chart.bar.fill") {
                    Text("coming soon")
                }
            }
            .tint(Theme.brand)
        }
    }
}
