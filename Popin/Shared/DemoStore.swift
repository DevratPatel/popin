import Foundation
import Observation

enum Participation: String, CaseIterable, Identifiable, Codable {
    case inPerson = "In person"
    case online = "Online"

    var id: String { rawValue }
}

struct PopinEvent: Identifiable {
    let id: String
    let title: String
    let game: String
    let host: String
    let dateLabel: String
    let location: String
    var design = InviteDesign()
    var stampStyle: EventStampStyle = .angular
    var description = "Come hang, catch the match, and make some noise. Your people will be here."

    static let sample = PopinEvent(
        id: "valorant-watch-party",
        title: "VALORANT\nWatch Party",
        game: "VALORANT",
        host: "Popin community",
        dateLabel: "Saturday · 6:00 PM",
        location: "Campus gaming lounge"
    )

    static let samples: [PopinEvent] = [
        sample,
        PopinEvent(
            id: "smash-social",
            title: "Smash\n& chill",
            game: "SMASH",
            host: "Campus FGC",
            dateLabel: "Friday · 7:00 PM",
            location: "Student center",
            design: InviteDesign(layout: .ticket, palette: .mint, mood: .pullUp),
            stampStyle: .seal,
            description: "Bring your controller and meet the local crew. Friendly sets, new rivals, and a spot for everyone."
        ),
        PopinEvent(
            id: "rocket-league-night",
            title: "One more\ngame?",
            game: "ROCKET LEAGUE",
            host: "After-hours club",
            dateLabel: "Sunday · 5:00 PM",
            location: "Esports lounge",
            design: InviteDesign(layout: .social, palette: .peach, mood: .goodCompany),
            stampStyle: .ticket,
            description: "An easy evening of Rocket League with the community. Find a teammate, watch a few games, and hang out."
        )
    ]
}

struct CollectedEventStamp: Identifiable {
    let event: PopinEvent
    let participation: Participation
    var id: String { event.id }
}

enum EventStampStyle: String, Codable {
    case angular, seal, ticket
    var aspectRatio: Double {
        switch self {
        case .angular: 0.83
        case .seal: 1
        case .ticket: 1.3
        }
    }
}

/// A stamp is placed once. Its page and loose arrangement survive later check-ins.
struct StampPlacement: Codable {
    let page: Int
    let slot: Int
    let x: Double
    let y: Double
    let angle: Double
    let scale: Double

    static func make(eventID: String, occupied: [StampPlacement]) -> StampPlacement {
        // Explicit hashing keeps the result stable across launches, unlike Swift's Hasher.
        let seed = eventID.utf8.reduce(UInt64(14_695_981_039_346_656_037)) { ($0 ^ UInt64($1)) &* 1_099_511_628_211 }
        func unit(_ shift: Int) -> Double { Double((seed >> shift) & 255) / 255 }
        var page = 1
        while occupied.filter({ $0.page == page }).count >= 3 { page += 1 }
        let used = Set(occupied.filter { $0.page == page }.map(\.slot))
        let available = (0..<3).filter { !used.contains($0) }
        let slot = available[Int(seed % UInt64(available.count))]
        let anchors: [(Double, Double)] = [(0.28, 0.26), (0.72, 0.39), (0.38, 0.68)]
        return StampPlacement(page: page, slot: slot,
            x: anchors[slot].0 + (unit(8) - 0.5) * 0.035,
            y: anchors[slot].1 + (unit(16) - 0.5) * 0.045,
            angle: (unit(24) - 0.5) * 28,
            scale: 0.9 + unit(32) * 0.14)
    }
}

struct PlacedEventStamp: Identifiable {
    let stamp: CollectedEventStamp
    let placement: StampPlacement
    var id: String { stamp.id }
}

/// Local prototype state only. A backend must validate real attendance and award stamps.
@MainActor
@Observable
final class DemoStore {
    let event = PopinEvent.sample
    let events = PopinEvent.samples
    private var reservations: [String: Participation]
    private var stamps: [String: Participation]
    private var stampPlacements: [String: StampPlacement]
    private(set) var inviteDraft: InviteDraft?
    private let defaults: UserDefaults

    // Preserve the original sample-event API for the Clip and existing clients.
    var rsvp: Participation? { rsvp(for: event) }
    var collectedStamp: Participation? { stamp(for: event) }
    var collectedStamps: [CollectedEventStamp] {
        events.compactMap { event in
            stamps[event.id].map { CollectedEventStamp(event: event, participation: $0) }
        }
    }

    var placedStamps: [PlacedEventStamp] {
        collectedStamps.compactMap { stamp in
            stampPlacements[stamp.id].map { PlacedEventStamp(stamp: stamp, placement: $0) }
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        inviteDraft = defaults.data(forKey: "demo.inviteDraft").flatMap { try? JSONDecoder().decode(InviteDraft.self, from: $0) }
        var loadedRSVPs = defaults.data(forKey: "demo.reservations").flatMap { try? JSONDecoder().decode([String: Participation].self, from: $0) } ?? [:]
        var loadedStamps = defaults.data(forKey: "demo.stamps").flatMap { try? JSONDecoder().decode([String: Participation].self, from: $0) } ?? [:]
        // Migrate attendance saved before the invite library existed.
        if loadedRSVPs[PopinEvent.sample.id] == nil, let raw = defaults.string(forKey: "demo.rsvp"), let value = Participation(rawValue: raw) {
            loadedRSVPs[PopinEvent.sample.id] = value
        }
        if loadedStamps[PopinEvent.sample.id] == nil, let raw = defaults.string(forKey: "demo.stamp"), let value = Participation(rawValue: raw) {
            loadedStamps[PopinEvent.sample.id] = value
        }
        var placements = defaults.data(forKey: "demo.stampPlacements").flatMap { try? JSONDecoder().decode([String: StampPlacement].self, from: $0) } ?? [:]
        placements = placements.filter { loadedStamps[$0.key] != nil }
        for eventID in loadedStamps.keys.sorted() where placements[eventID] == nil {
            placements[eventID] = StampPlacement.make(eventID: eventID, occupied: Array(placements.values))
        }
        reservations = loadedRSVPs
        stamps = loadedStamps
        stampPlacements = placements
        if let data = try? JSONEncoder().encode(placements) { defaults.set(data, forKey: "demo.stampPlacements") }
    }

    func rsvp(for event: PopinEvent) -> Participation? { reservations[event.id] }
    func stamp(for event: PopinEvent) -> Participation? { stamps[event.id] }

    func saveInviteDraft(_ draft: InviteDraft) {
        guard draft.isValid, let data = try? JSONEncoder().encode(draft) else { return }
        defaults.set(data, forKey: "demo.inviteDraft")
        inviteDraft = draft
    }

    func reserve(_ participation: Participation, for event: PopinEvent = .sample) {
        guard stamps[event.id] == nil else { return }
        reservations[event.id] = participation
        persistAttendance()
    }

    func simulateCheckIn(for event: PopinEvent = .sample) {
        guard let rsvp = reservations[event.id], stamps[event.id] == nil else { return }
        stamps[event.id] = rsvp
        stampPlacements[event.id] = StampPlacement.make(eventID: event.id, occupied: Array(stampPlacements.values))
        persistAttendance()
    }

    private func persistAttendance() {
        if let data = try? JSONEncoder().encode(reservations) { defaults.set(data, forKey: "demo.reservations") }
        if let data = try? JSONEncoder().encode(stamps) { defaults.set(data, forKey: "demo.stamps") }
        if let data = try? JSONEncoder().encode(stampPlacements) { defaults.set(data, forKey: "demo.stampPlacements") }
    }

    func reset() {
        reservations = [:]
        stamps = [:]
        stampPlacements = [:]
        for key in ["demo.reservations", "demo.stamps", "demo.rsvp", "demo.stamp", "demo.stampPlacements"] { defaults.removeObject(forKey: key) }
    }
}

// Deliberately bounded art direction: creators choose a composition, palette and mood.
enum InviteLayout: String, CaseIterable, Codable, Identifiable {
    case bold = "Bold", social = "Social", ticket = "Ticket"
    var id: String { rawValue }
}

enum InvitePalette: String, CaseIterable, Codable, Identifiable {
    case lilac = "Lilac", peach = "Peach", mint = "Mint"
    var id: String { rawValue }
}

enum InviteMood: String, CaseIterable, Codable, Identifiable {
    case gameOn = "Game on", pullUp = "Pull up", goodCompany = "Good company"
    var id: String { rawValue }
    var headline: String {
        switch self {
        case .gameOn: "game\non."
        case .pullUp: "pull\nup."
        case .goodCompany: "good\ncompany."
        }
    }
}

struct InviteDesign: Codable, Equatable {
    var layout: InviteLayout = .bold
    var palette: InvitePalette = .lilac
    var mood: InviteMood = .gameOn
}

struct InviteDraft: Codable, Equatable {
    var title = ""
    var host = ""
    var location = ""
    var game = "VALORANT"
    var startsAt = Date.now.addingTimeInterval(86_400)
    var note = ""
    var design = InviteDesign()

    var isValid: Bool {
        [title, host, location, game].allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}
