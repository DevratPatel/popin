import SwiftUI

private enum ComposerStep: String, CaseIterable, Identifiable {
    case details = "Details", design = "Look & feel"
    var id: String { rawValue }
}

/// A guided invitation designer. The composition is always handled by Popin.
struct InviteComposer: View {
    let store: DemoStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var draft: InviteDraft
    @State private var step: ComposerStep = .details
    @State private var showDiscard = false
    private let original: InviteDraft

    init(store: DemoStore) {
        self.store = store
        let initial = store.inviteDraft ?? InviteDraft()
        original = initial
        _draft = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let wide = geometry.size.width >= 600 && !dynamicTypeSize.isAccessibilitySize
                VStack(spacing: 0) {
                    Picker("Invite setup", selection: $step) {
                        ForEach(ComposerStep.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    if wide {
                        HStack(alignment: .top, spacing: 0) {
                            ScrollView { preview.padding(24) }
                                .frame(width: geometry.size.width * 0.46)
                            editor(showPreview: false)
                        }
                    } else {
                        editor(showPreview: true)
                    }
                }
            }
            .background(PopinTheme.background)
            .navigationTitle("Make it your invite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") {
                        if draft != original { showDiscard = true } else { dismiss() }
                    }
                    .labelStyle(.iconOnly)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 9) {
                    if step == .details {
                        Button("Choose the look") { step = .design }
                            .buttonStyle(PopinButtonStyle())
                    } else {
                        Button("Save invite draft") {
                            store.saveInviteDraft(draft)
                            dismiss()
                        }
                        .buttonStyle(PopinButtonStyle())
                        .disabled(!draft.isValid)
                        .opacity(draft.isValid ? 1 : 0.45)
                    }
                    Text("Saved on this device · Your invite isn’t published yet")
                        .font(.caption2)
                        .foregroundStyle(PopinTheme.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 12)
                .background(PopinTheme.background)
            }
            .confirmationDialog("Discard your unsaved changes?", isPresented: $showDiscard, titleVisibility: .visible) {
                Button("Discard changes", role: .destructive) { dismiss() }
            }
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled(draft != original)
        .tint(PopinTheme.accent)
    }

    private func editor(showPreview: Bool) -> some View {
        Form {
            if showPreview {
                Section {
                    preview
                        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                        .listRowBackground(Color.clear)
                }
            }
            if step == .details { detailFields }
            else { designFields }
        }
        .scrollContentBackground(.hidden)
    }

    private var detailFields: some View {
        Group {
            Section("The essentials") {
                TextField("Event name", text: limited($draft.title, to: 80))
                TextField("Hosted by", text: limited($draft.host, to: 50))
                TextField("Game or category", text: limited($draft.game, to: 24))
                DatePicker("When", selection: $draft.startsAt, displayedComponents: [.date, .hourAndMinute])
                TextField("Venue or meeting place", text: limited($draft.location, to: 80))
            }
            Section {
                TextField("Give your people a little context…", text: limited($draft.note, to: 280), axis: .vertical)
                    .lineLimit(3...5)
            } header: { Text("A note for your guests") }
            footer: { Text("You set the details. Popin takes care of the composition.") }
        }
    }

    private var designFields: some View {
        Group {
            Section("Pick a composition") {
                ForEach(InviteLayout.allCases) { layout in
                    choice(layout.rawValue, subtitle: layoutDescription(layout), selected: draft.design.layout == layout) { draft.design.layout = layout }
                }
            }
            Section("Set the mood") {
                Picker("Headline", selection: $draft.design.mood) {
                    ForEach(InviteMood.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
            }
            Section {
                HStack(spacing: 14) {
                    ForEach(InvitePalette.allCases) { palette in
                        Button { draft.design.palette = palette } label: {
                            VStack(spacing: 8) {
                                Circle().fill(palette.color)
                                    .frame(width: 48, height: 48)
                                    .overlay {
                                        if draft.design.palette == palette {
                                            Image(systemName: "checkmark").font(.headline).foregroundStyle(PopinTheme.background)
                                        }
                                    }
                                Text(palette.rawValue).font(.caption).foregroundStyle(PopinTheme.paper)
                            }
                            .frame(maxWidth: .infinity, minHeight: 80)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(palette.rawValue)
                        .accessibilityAddTraits(draft.design.palette == palette ? .isSelected : [])
                    }
                }
                .padding(.vertical, 4)
            } header: { Text("Choose a color") }
            footer: { Text("A few good choices. Every combination is designed to work together.") }
            if !draft.isValid {
                Section {
                    Button("Finish your event details") { step = .details }
                    Text("Add an event name, host, game or category, and meeting place before saving.")
                        .font(.footnote).foregroundStyle(PopinTheme.secondary)
                }
            }
        }
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("LIVE PREVIEW").tracking(1.6)
                Spacer()
                Text("DRAFT")
            }
            .font(.system(.caption2, design: .monospaced, weight: .medium))
            .foregroundStyle(PopinTheme.secondary)
            InviteArtwork(design: draft.design, game: draft.game.isEmpty ? "YOUR EVENT" : draft.game)
            Text(draft.title.isEmpty ? "Your next watch party" : draft.title)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(PopinTheme.paper)
            VStack(alignment: .leading, spacing: 6) {
                Text(draft.startsAt.formatted(date: .abbreviated, time: .shortened))
                Text(draft.location.isEmpty ? "Somewhere good" : draft.location)
                Text("Hosted by \(draft.host.isEmpty ? "you" : draft.host)")
            }
            .font(.caption)
            .foregroundStyle(PopinTheme.secondary)
            if !draft.note.isEmpty {
                Text(draft.note).font(.subheadline).foregroundStyle(PopinTheme.paper)
            }
        }
        .frame(maxWidth: 440)
        .frame(maxWidth: .infinity)
    }

    private func choice(_ title: String, subtitle: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline).foregroundStyle(PopinTheme.paper)
                    Text(subtitle).font(.caption).foregroundStyle(PopinTheme.secondary)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? PopinTheme.lilac : PopinTheme.secondary)
            }
            .padding(.vertical, 6)
        }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func layoutDescription(_ layout: InviteLayout) -> String {
        switch layout {
        case .bold: "Big type. A little attitude."
        case .social: "Your people, front and center."
        case .ticket: "A keepsake before the night begins."
        }
    }

    private func limited(_ binding: Binding<String>, to limit: Int) -> Binding<String> {
        Binding(get: { binding.wrappedValue }, set: { binding.wrappedValue = String($0.prefix(limit)) })
    }
}
