import SwiftUI

private enum PassportSheet: Identifiable {
    case options
    case preview(PopinEvent)
    case stamp(CollectedEventStamp)

    var id: String {
        switch self {
        case .options: "options"
        case .preview(let event): "preview-\(event.id)"
        case .stamp(let stamp): "stamp-\(stamp.id)"
        }
    }
}

private enum PassportInk {
    static let primary = Color(red: 45 / 255, green: 66 / 255, blue: 91 / 255)
    static let secondary = Color(red: 113 / 255, green: 126 / 255, blue: 134 / 255)
    static let paper = Color(red: 244 / 255, green: 238 / 255, blue: 220 / 255)
}

struct PassportView: View {
    let store: DemoStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var leaf = 0
    @State private var sheet: PassportSheet?

    private var pageCount: Int {
        let lastUsedPage = store.placedStamps.map(\.placement.page).max() ?? 1
        return max(4, (lastUsedPage + 2) / 2 * 2)
    }

    var body: some View {
        GeometryReader { geometry in
            let spread = geometry.size.width >= 600 && !dynamicTypeSize.isAccessibilitySize
            PassportPageCurl(leaf: $leaf, spread: spread, reduceMotion: reduceMotion, count: pageCount) { number in
                page(number: number)
            }
            .id(spread)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .overlay {
                if spread {
                    LinearGradient(colors: [.clear, .black.opacity(0.13), .white.opacity(0.2), .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: 22, height: geometry.size.height)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        .allowsHitTesting(false)
                }
            }
            .overlay { edgeControls(spread: spread) }
        }
        .ignoresSafeArea(.container)
        .onChange(of: pageCount) { _, count in leaf = min(leaf, count - 1) }
        .background(PassportInk.paper.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar, .tabBar)
        .toolbar(.hidden, for: .bottomBar)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Menu("Preview stamps", systemImage: "sparkles") {
                        ForEach(store.events) { event in
                            Button(event.title.replacingOccurrences(of: "\n", with: " ")) { sheet = .preview(event) }
                        }
                    }
                    Button("About this demo", systemImage: "info.circle") { sheet = .options }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("Passport options")
                .tint(.white)
            }
        }
        .sheet(item: $sheet) { destination in
            switch destination {
            case .options: DemoDetailsView(store: store)
            case .stamp(let stamp): PassportStampDetail(event: stamp.event, participation: stamp.participation, isPreview: false)
            case .preview(let event): PassportStampDetail(event: event, participation: .inPerson, isPreview: true)
            }
        }
    }

    private func turnPage(_ direction: Int, spread: Bool) {
        let step = spread ? 2 : 1
        let first = spread ? leaf / 2 * 2 : leaf
        leaf = min(pageCount - step, max(0, first + direction * step))
    }

    private func canTurn(forward: Bool, spread: Bool) -> Bool {
        forward ? leaf < pageCount - (spread ? 2 : 1) : leaf >= (spread ? 2 : 1)
    }

    private func edgeControls(spread: Bool) -> some View {
        HStack(spacing: 0) {
            turnButton(forward: false, spread: spread).frame(width: 32)
            Spacer(minLength: 0)
            turnButton(forward: true, spread: spread).frame(width: 32)
        }
        .overlay(alignment: .bottomLeading) { turnButton(forward: false, spread: spread).frame(width: 72, height: 72) }
        .overlay(alignment: .bottomTrailing) { turnButton(forward: true, spread: spread).frame(width: 72, height: 72) }
    }

    private func turnButton(forward: Bool, spread: Bool) -> some View {
        Button { turnPage(forward ? 1 : -1, spread: spread) } label: {
            Color.clear.contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .allowsHitTesting(canTurn(forward: forward, spread: spread))
        .accessibilityHidden(!canTurn(forward: forward, spread: spread))
        .accessibilityLabel(forward ? "Turn next page" : "Turn previous page")
    }

    private var ownerIntroduction: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("THIS PASSPORT BELONGS TO")
                    .font(.system(.caption2, design: .monospaced, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(PassportInk.secondary)
                Text("Popin’s Crew")
                    .font(.system(.largeTitle, design: .serif, weight: .medium))
                    .foregroundStyle(PassportInk.primary)
                    .accessibilityAddTraits(.isHeader)
                Rectangle()
                    .fill(PassportInk.primary.opacity(0.18))
                    .frame(height: 1)
                Text("Your event stamps live here. Collect them when you attend, and tap a stamp to see its details.")
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(PassportInk.primary.opacity(0.8))
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 16)
        }
        .scrollIndicators(.hidden)
    }

    private func page(number: Int) -> some View {
        GeometryReader { pageGeometry in
            ZStack {
                PassportPaper(number: number)
                if number == 0 {
                    ownerIntroduction
                        .frame(width: max(0, pageGeometry.size.width - 80), height: pageGeometry.size.height * 0.62)
                        .position(x: pageGeometry.size.width / 2, y: pageGeometry.size.height * 0.43)
                } else {
                    ForEach(store.placedStamps.filter { $0.placement.page == number }) { placed in
                        let stamp = placed.stamp
                        let placement = placed.placement
                        Button { sheet = .stamp(stamp) } label: {
                            FoilStampSticker(participation: stamp.participation, game: stamp.event.game, eventTitle: stamp.event.title.replacingOccurrences(of: "\n", with: " "), style: stamp.event.stampStyle)
                        }
                        .buttonStyle(.plain)
                        .frame(width: min(220, min(pageGeometry.size.width * 0.43, pageGeometry.size.height * 0.28)) * placement.scale)
                        .rotationEffect(.degrees(placement.angle))
                        .position(x: pageGeometry.size.width * placement.x, y: pageGeometry.size.height * placement.y)
                        .accessibilityLabel("\(stamp.event.title.replacingOccurrences(of: "\n", with: " ")) stamp. Open event details.")
                    }
                }
                Text(String(format: "%02d", number + 1))
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .foregroundStyle(PassportInk.primary.opacity(0.55))
                    .position(x: pageGeometry.size.width / 2, y: pageGeometry.size.height - 38)
                    .accessibilityHidden(true)
            }
        }
        .clipped()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Passport page \(number + 1) of \(pageCount)")
    }
}

/// Printed paper inspired by passport visa pages: engraved lines, pale landscape
/// contours, security rosettes, and generous space for actual stamps.
private struct PassportPaper: View {
    let number: Int

    var body: some View {
        Canvas { context, size in
            let bounds = CGRect(origin: .zero, size: size)
            context.fill(Path(bounds), with: .linearGradient(Gradient(colors: [PassportInk.paper, Color(red: 0.90, green: 0.92, blue: 0.86), PassportInk.paper]), startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))
            let ink = PassportInk.primary
            for row in 0..<Int(size.height / 12) + 2 {
                var path = Path()
                for column in 0...120 {
                    let x = size.width * Double(column) / 120
                    let y = Double(row) * 12 + sin(x / 28 + Double(row) * 0.22) * 7
                    if column == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
                context.stroke(path, with: .color(ink.opacity(0.055)), lineWidth: 0.45)
            }
            // Low-contrast landscape engraving stays beneath the collection.
            for contour in 0..<25 {
                var path = Path()
                for step in 0...120 {
                    let x = size.width * Double(step) / 120
                    let ridge = sin(x / size.width * 5 + Double(number) * 0.7) * 0.06 + sin(x / size.width * 14) * 0.025
                    let y = size.height * (0.75 + ridge) + Double(contour) * 3
                    if step == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
                context.stroke(path, with: .color(ink.opacity(0.07)), lineWidth: 0.5)
            }
            let center = CGPoint(x: size.width * (number.isMultiple(of: 2) ? 0.24 : 0.76), y: size.height * 0.23)
            for ring in 0..<18 {
                var path = Path()
                for step in 0...180 {
                    let angle = Double(step) / 180 * .pi * 2
                    let radius = Double(24 + ring * 3) + sin(angle * 12) * 5
                    let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
                    if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }
                path.closeSubpath()
                context.stroke(path, with: .color(ink.opacity(0.065)), lineWidth: 0.4)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct PassportStampDetail: View {
    let event: PopinEvent
    let participation: Participation
    let isPreview: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    FoilStampSticker(participation: participation, game: event.game, eventTitle: event.title.replacingOccurrences(of: "\n", with: " "), style: event.stampStyle)
                        .frame(maxWidth: 290)
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }
                Section("Event") {
                    LabeledContent("Name", value: event.title.replacingOccurrences(of: "\n", with: " "))
                    LabeledContent("When", value: event.dateLabel)
                    LabeledContent("Where", value: event.location)
                    LabeledContent("Host", value: event.host)
                    LabeledContent("Attendance", value: participation.rawValue)
                }
                Section {
                    Text(isPreview ? "Preview only. This sticker has not been collected." : "Sample event. This stamp was collected using simulated check-in.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(isPreview ? "Sticker preview" : "Stamp details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    Button("Done", systemImage: "checkmark") { dismiss() }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}
