import SwiftUI

@main
struct PopinApp: App {
    @State private var store = DemoStore()
    @State private var selectedTab = 0
    @State private var showComposer = false

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    InviteLibraryView(store: store, onCreate: { showComposer = true })
                }
                .tabItem { Label("Invite", systemImage: "envelope") }
                .tag(0)

                NavigationStack {
                    PassportView(store: store)
                }
                .tabItem { Label("Passport", systemImage: "book.closed") }
                .tag(1)
            }
            .tint(PopinTheme.accent)
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showComposer) { InviteComposer(store: store) }
        }
    }
}
