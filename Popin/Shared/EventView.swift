import SwiftUI

private enum EventSheet: String, Identifiable {
    case rsvp, stamp, demo
    var id: String { rawValue }
}

struct EventView: View {
    let store: DemoStore
    var event = PopinEvent.sample
    var showsBackButton = false
    @Environment(\.dismiss) private var dismiss
    var onCreate: (() -> Void)? = nil
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var sheet: EventSheet?

    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width >= 600 && !dynamicTypeSize.isAccessibilitySize
            ScrollView {
                VStack(alignment: .leading, spacing: wide ? 36 : 24) {
                    header
                    if wide {
                        HStack(alignment: .top, spacing: 32) {
                            InviteArtwork(design: event.design, game: event.game, portrait: true)
                                .frame(width: min(460, (geometry.size.width - 80) * 0.48))
                            VStack(alignment: .leading, spacing: 28) {
                                invitation
                                eventDetails
                                aboutEvent
                                responseBar
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.bottom, 32)
                    } else {
                        InviteArtwork(design: event.design, game: event.game)
                        invitation
                        eventDetails
                        aboutEvent
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .frame(maxWidth: wide ? 1100 : 560)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !wide { responseBar.padding(.horizontal, 24).padding(.top, 14).background(PopinTheme.background) }
            }
        }
        .background(PopinTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.visible, for: .tabBar, .bottomBar)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                if showsBackButton {
                    Button("Invites", systemImage: "chevron.left") { dismiss() }
                        .labelStyle(.iconOnly)
                        .tint(.white)
                }
                Spacer()
                if let onCreate {
                    Button("Create event", systemImage: "plus", action: onCreate)
                        .labelStyle(.iconOnly)
                        .tint(.white)
                }
                Menu {
                    if store.rsvp(for: event) != nil && store.stamp(for: event) == nil {
                        Button("Edit RSVP", systemImage: "pencil") { sheet = .rsvp }
                    }
                    Button("About this demo", systemImage: "info.circle") { sheet = .demo }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("Invite options")
                .tint(.white)
            }
        }
        .sheet(item: $sheet) { destination in
            switch destination {
            case .rsvp: RSVPView(store: store, event: event)
            case .stamp: StampSheet(store: store, event: event)
            case .demo: DemoDetailsView(store: store)
            }
        }
    }

    private var aboutEvent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("The best plays deserve good company.")
                .font(.headline)
            Text(event.description)
                .font(.subheadline)
                .foregroundStyle(PopinTheme.secondary)
                .lineSpacing(4)
        }
        .padding(.top, 4)
        .padding(.bottom, 16)
    }

    private var header: some View {
        HStack {
            PopinWordmark()
            Spacer()
            Text("Sample invite")
                .font(.caption)
                .foregroundStyle(PopinTheme.secondary)
        }
    }

    private var invitation: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(event.title)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .tracking(-1)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(PopinTheme.paper)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 9) {
                Image("PopinPin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 21)
                    .padding(7)
                    .background(PopinTheme.surface, in: Circle())
                    .accessibilityHidden(true)
                Text("Hosted by \(event.host)")
                    .font(.subheadline)
                    .foregroundStyle(PopinTheme.secondary)
            }
        }
    }

    private var eventDetails: some View {
        VStack(alignment: .leading, spacing: 20) {
            detailRow("calendar", title: event.dateLabel, subtitle: "Settle in before the first round")
            detailRow("mappin", title: event.location, subtitle: "Or join the watch party online")
        }
        .padding(.vertical, 8)
    }

    private func detailRow(_ symbol: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(PopinTheme.lilac)
                .frame(width: 26, height: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(PopinTheme.paper)
                Text(subtitle).font(.caption).foregroundStyle(PopinTheme.secondary)
            }
        }
    }

    private var responseBar: some View {
        VStack(spacing: 12) {
            if let rsvp = store.rsvp(for: event) {
                HStack {
                    Label(store.stamp(for: event) == nil ? "You’re going" : "Memory collected", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(PopinTheme.lilac)
                    Spacer()
                    Text(rsvp.rawValue).foregroundStyle(PopinTheme.secondary)
                }
                .font(.subheadline.weight(.medium))
            }
            Button {
                if store.rsvp(for: event) == nil { sheet = .rsvp }
                else { sheet = .stamp }
            } label: {
                HStack(spacing: 10) {
                    Text(store.rsvp(for: event) == nil ? "I’m in" : store.stamp(for: event) == nil ? "Try demo check-in" : "View your stamp")
                    Image(systemName: store.rsvp(for: event) == nil ? "arrow.up.right" : store.stamp(for: event) == nil ? "qrcode.viewfinder" : "sparkles")
                }
            }
            .buttonStyle(PopinButtonStyle())
            if store.rsvp(for: event) == nil {
                Text("Sample invite · RSVP stays on this device")
                    .font(.caption2)
                    .foregroundStyle(PopinTheme.secondary)
            }
        }
        .padding(.bottom, 12)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
        .background(PopinTheme.background)
    }
}

private struct RSVPView: View {
    let store: DemoStore
    let event: PopinEvent
    @Environment(\.dismiss) private var dismiss
    @State private var participation: Participation

    init(store: DemoStore, event: PopinEvent) {
        self.store = store
        self.event = event
        _participation = State(initialValue: store.rsvp(for: event) ?? .inPerson)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("See you there.")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        Text("How are you joining?")
                            .foregroundStyle(PopinTheme.secondary)
                    }
                    VStack(spacing: 12) {
                        option(.inPerson, symbol: "mappin.and.ellipse", detail: "Meet the crowd at the lounge")
                        option(.online, symbol: "play.rectangle", detail: "Catch the match from anywhere")
                    }
                    Button(store.rsvp(for: event) == nil ? "Count me in" : "Save my RSVP") {
                        store.reserve(participation, for: event)
                        dismiss()
                    }
                    .buttonStyle(PopinButtonStyle())
                    Text("This is a sample event. Your RSVP is saved only on this device.")
                        .font(.footnote)
                        .foregroundStyle(PopinTheme.secondary)
                }
                .padding(24)
            }
            .background(PopinTheme.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                        .labelStyle(.iconOnly)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(PopinTheme.background)
    }

    private func option(_ value: Participation, symbol: String, detail: String) -> some View {
        Button { participation = value } label: {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.title3)
                    .frame(width: 28)
                    .foregroundStyle(PopinTheme.lilac)
                VStack(alignment: .leading, spacing: 4) {
                    Text(value.rawValue).font(.headline).foregroundStyle(PopinTheme.paper)
                    Text(detail).font(.caption).foregroundStyle(PopinTheme.secondary)
                }
                Spacer(minLength: 4)
                Image(systemName: participation == value ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(participation == value ? PopinTheme.lilac : PopinTheme.secondary)
            }
            .padding(18)
            .background(PopinTheme.surface, in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(participation == value ? PopinTheme.accent : .clear, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(participation == value ? .isSelected : [])
    }
}

private struct StampSheet: View {
    let store: DemoStore
    let event: PopinEvent
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text(store.stamp(for: event) == nil ? "Make it a memory." : "A night to keep.")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)
                    if let stamp = store.stamp(for: event) {
                        StampView(participation: stamp, game: event.game, eventTitle: event.title.replacingOccurrences(of: "\n", with: " "), style: event.stampStyle)
                        Text("Saved to your passport.")
                            .foregroundStyle(PopinTheme.secondary)
                        Button("Keep the memory") { dismiss() }
                            .buttonStyle(PopinButtonStyle())
                    } else {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 72, weight: .light))
                            .foregroundStyle(PopinTheme.lilac)
                            .padding(24)
                        Text("At a real event, you’ll check in to collect your stamp. For now, try it here.")
                            .foregroundStyle(PopinTheme.secondary)
                            .multilineTextAlignment(.center)
                        Button("Simulate check-in") { store.simulateCheckIn(for: event) }
                            .buttonStyle(PopinButtonStyle())
                        Text("Demo only · No QR code is scanned")
                            .font(.footnote)
                            .foregroundStyle(PopinTheme.secondary)
                    }
                }
                .padding(24)
                .padding(.top, 24)
            }
            .background(PopinTheme.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }.labelStyle(.iconOnly)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .presentationBackground(PopinTheme.background)
    }
}

struct DemoDetailsView: View {
    let store: DemoStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("A little preview of Popin: join a watch party, try check-in, and keep a stamp.")
                    Text("This event is a sample. RSVPs and stamps stay on this device. No real RSVP is sent, and check-in is simulated.")
                }
                Section {
                    Button("Reset demo", role: .destructive) { confirmReset = true }
                } footer: {
                    Text("The app and App Clip currently keep separate demo data.")
                }
            }
            .navigationTitle("About this demo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .confirmationDialog("Reset all sample RSVPs and collected stamps?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset demo", role: .destructive) { store.reset(); dismiss() }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview("Invitation") {
    EventView(store: DemoStore(defaults: UserDefaults(suiteName: "preview.invitation")!))
        .preferredColorScheme(.dark)
}
