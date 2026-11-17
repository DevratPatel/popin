import SwiftUI

struct InviteLibraryView: View {
    let store: DemoStore
    let onCreate: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showDemo = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Invites")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(PopinTheme.paper)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    Text("Sample events")
                        .font(.caption)
                        .foregroundStyle(PopinTheme.secondary)
                }
                if let draft = store.inviteDraft {
                    Button(action: onCreate) {
                        HStack(spacing: 14) {
                            Image(systemName: "square.and.pencil")
                                .font(.title3)
                                .foregroundStyle(PopinTheme.paper)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(draft.title)
                                    .font(.headline)
                                    .foregroundStyle(PopinTheme.paper)
                                Text("Your draft · Not published")
                                    .font(.caption)
                                    .foregroundStyle(PopinTheme.secondary)
                            }
                            Spacer()
                            Text("Edit").font(.subheadline).foregroundStyle(PopinTheme.paper)
                        }
                        .padding(18)
                        .background(PopinTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }
                LazyVGrid(columns: dynamicTypeSize.isAccessibilitySize ? [GridItem(.flexible())] : [GridItem(.adaptive(minimum: 260), spacing: 24, alignment: .top)], alignment: .leading, spacing: 32) {
                    ForEach(store.events) { event in
                        NavigationLink(value: event.id) {
                            inviteCard(event)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(event.title.replacingOccurrences(of: "\n", with: " ")), \(event.dateLabel). Open invite.")
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 1200)
            .frame(maxWidth: .infinity)
        }
        .background(PopinTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar, .tabBar)
        .toolbar(.hidden, for: .bottomBar)
        .toolbar {
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: .topBarLeading) { PopinWordmark() }
                    .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .topBarLeading) { PopinWordmark() }
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Create event", systemImage: "plus", action: onCreate)
                    .labelStyle(.iconOnly)
                    .tint(.white)
                Menu {
                    Button("About this demo", systemImage: "info.circle") { showDemo = true }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("Invite options")
                .tint(.white)
            }
        }
        .navigationDestination(for: String.self) { eventID in
            if let event = store.events.first(where: { $0.id == eventID }) {
                EventView(store: store, event: event, showsBackButton: true, onCreate: onCreate)
            }
        }
        .sheet(isPresented: $showDemo) { DemoDetailsView(store: store) }
    }

    private func inviteCard(_ event: PopinEvent) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            InviteArtwork(design: event.design, game: event.game)
            VStack(alignment: .leading, spacing: 8) {
                Text(event.title.replacingOccurrences(of: "\n", with: " "))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(PopinTheme.paper)
                    .fixedSize(horizontal: false, vertical: true)
                Text(event.dateLabel)
                    .font(.subheadline)
                    .foregroundStyle(PopinTheme.paper.opacity(0.8))
                Text(event.location)
                    .font(.caption)
                    .foregroundStyle(PopinTheme.secondary)
                if store.stamp(for: event) != nil {
                    Label("Stamp collected", systemImage: "checkmark.seal")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(PopinTheme.lilac)
                        .padding(.top, 4)
                } else if store.rsvp(for: event) != nil {
                    Label("You’re going", systemImage: "checkmark.circle")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(PopinTheme.lilac)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
