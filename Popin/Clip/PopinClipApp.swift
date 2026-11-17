import SwiftUI

@main
struct PopinClipApp: App {
    @State private var store = DemoStore()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                EventView(store: store)
            }
            .tint(PopinTheme.accent)
            .preferredColorScheme(.dark)
        }
    }
}
