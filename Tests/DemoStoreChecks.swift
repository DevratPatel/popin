import Foundation

@main
struct DemoStoreChecks {
    @MainActor
    static func main() {
        let suite = "popin.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = DemoStore(defaults: defaults)
        store.simulateCheckIn()
        precondition(store.collectedStamp == nil, "Check-in requires an RSVP")

        store.reserve(.inPerson)
        precondition(DemoStore(defaults: defaults).rsvp == .inPerson, "RSVP must survive a new session")
        store.simulateCheckIn()
        store.reserve(.online)
        precondition(store.collectedStamp == .inPerson, "An awarded stamp cannot change participation")
        precondition(store.rsvp == .inPerson, "RSVP stays consistent with the stamp")
        precondition(DemoStore(defaults: defaults).collectedStamp == .inPerson, "Stamp must survive a new session")

        store.reset()
        let reloaded = DemoStore(defaults: defaults)
        precondition(reloaded.rsvp == nil && reloaded.collectedStamp == nil, "Reset must clear saved demo data")
        reloaded.reserve(.online)
        reloaded.simulateCheckIn()
        precondition(reloaded.collectedStamp == .online, "Online check-in must award the online variant")
        print("DemoStore checks passed")
    }
}
