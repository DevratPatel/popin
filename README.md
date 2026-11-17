# Popin

An esports event app inspired by Partiful, with collectible attendance stamps.

## First prototype

Open `Popin.xcodeproj` in Xcode. Choose the **Popin** scheme for the full app or **PopinClip** for the lightweight experience. The minimum deployment target is iOS 17.

- **Invite:** browse three sample event cards, then tap one for its detail/RSVP flow. Wider detail windows use artwork on the left and details/RSVP on the right; narrow windows use a vertical layout with a pinned action. Native trailing navigation includes a separate white + button, a white options menu, and a back button on details. RSVP and collected stamps are saved independently for each event.
- **Passport:** at least four full-screen numbered cream pages. Native UIKit page curls support swipes, outer-edge taps, and bottom-corner taps. Layouts at least 600 points wide show two pages around a center binding; smaller windows and accessibility type show single pages. The spread fills the full container and is split equally at the center, including beneath native navigation. The first left page introduces the owner and explains the collection. Remaining pages show only security-style printed artwork, page numbers, and reflective foil stamps. Each event has its own shape, palette, and artwork (angular sticker, round seal, or ticket). Up to three stamps share a page with varied positions, sizes, and angles. Placements are saved and stay stable as the collection grows; additional page pairs are added when needed. There is no cover screen. Tap a stamp for event details. Native tabs remain visible; the trailing native toolbar menu contains previews of each event’s stamp and demo options.
- **+ Create event:** a guided local invite designer with three layouts (Bold, Social, Ticket), three palettes (Lilac, Peach, Mint), and three headline moods. Event details and a bounded note are editable, with a live preview. Drafts persist locally; there is no publishing yet. No uploads, arbitrary positioning, custom fonts, or unrestricted color controls.
- **App Clip:** the shared event/RSVP/check-in flow, with its own entry point.

Demo state persists locally through UserDefaults, with attendance keyed by stable sample-event IDs. Previous single-event attendance is migrated. The two targets currently have separate storage. Events are sample data; check-in is a clearly labeled simulation. There are no accounts, network requests, SMS messages, real QR validation, or live App Clip invocation yet. The shared invite uses original Popin lettering and pin exports from Figma, a native typographic cover, and a solid near-black background. The UI remains a local prototype.

## Structure

- `Popin/App`: full app entry point, invite library, passport, native page-curl bridge, and guided invite composer.
- `Popin/Clip`: App Clip entry point, metadata, and entitlements.
- `Popin/Shared`: event screen, event model, local demo state, and theme shared by both targets.
- `AGENTS.md`: persistent product context and project decisions.

The root background is solid near-black violet (`#100E14`), matching the current logo background direction.

## Build

For an unsigned device SDK compile of both targets:

```sh
xcodebuild -project Popin.xcodeproj -scheme Popin \
  -configuration Debug -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath /private/tmp/popin-derived CODE_SIGNING_ALLOWED=NO build
```

For interactive testing, install an iOS simulator runtime in Xcode and select an iPhone simulator. For physical devices and distribution, select a development team and replace the placeholder identifiers `com.example.popin` and `com.example.popin.Clip`, including the parent identifier in `PopinClip.entitlements`.

Run the local demo state checks on macOS:

```sh
swiftc -parse-as-library -module-cache-path /private/tmp/popin-swift-cache \
  Popin/Shared/DemoStore.swift Tests/DemoStoreChecks.swift -o /private/tmp/popin-state-checks
/private/tmp/popin-state-checks
```

## Build sequence

1. The user is handling testing. Manually review the invite and passport, including the Duo folded/unfolded, large Dynamic Type, and VoiceOver. Do not run tests unless requested.
2. Add the shared backend: identity, events, RSVPs, validated check-ins, and stamp ownership. Choose a backend before implementation; none is configured yet.
3. Connect local organizer drafts to real event creation/publishing and implement QR/link check-in with server validation. Public QR links alone must not be treated as proof of physical presence.
4. Configure event URL routing and the App Clip launch experience with real event data. Set up signing, App Store Connect, and associated-domain hosting if using custom URLs.
5. Verify the app/Clip account handoff and passport continuity, then test through TestFlight and at a small event.

Keep SMS, sponsor features, and live crowd interactions outside the first working event flow.

## Trying the App Clip

For the lightweight UI, open `Popin.xcodeproj`, select the **PopinClip** scheme and a simulator, and press **Run (⌘R)**. Xcode opens the Clip directly; this does not display Apple’s App Clip card. The sample RSVP and check-in are local, and Clip data is separate from the full app.

To see the launch card on a physical iPhone:

1. Configure a development team and unique app/Clip bundle IDs; update the parent identifier in the Clip entitlements to match. Enable Developer Mode on your iPhone.
2. Run **PopinClip** on that iPhone once to cache a development-signed build.
3. In iPhone **Settings → Developer → Local Experiences → Register Local Experience**, enter a local-only invocation URL (for example `https://example.com/popin/watch-party`), your actual Clip bundle ID, a title/subtitle, **Open**, and a header image.
4. Scan a QR code containing that same URL using Code Scanner. The local experience can display the card and launch the cached Clip; a hosted domain association is not needed for this local QR route.

The example URL is not a deployed Popin event. URL-specific event routing is not implemented yet. Later, `_XCAppClipURL` under **Edit Scheme → Run → Arguments → Environment Variables** can supply a URL while developing that handler; it does not display the card.

See [Apple’s App Clip launch guidance](https://developer.apple.com/documentation/appclip/testing-the-launch-experience-of-your-app-clip). Public launch links still require signing, deployment, domain/experience configuration, and App Store Connect setup.
