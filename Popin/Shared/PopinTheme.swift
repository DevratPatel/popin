import SwiftUI

enum PopinTheme {
    static let background = Color(red: 16 / 255, green: 14 / 255, blue: 20 / 255)
    static let surface = Color(red: 29 / 255, green: 26 / 255, blue: 35 / 255)
    static let accent = Color(red: 177 / 255, green: 133 / 255, blue: 247 / 255)
    static let lilac = Color(red: 190 / 255, green: 157 / 255, blue: 246 / 255)
    static let paper = Color(red: 246 / 255, green: 241 / 255, blue: 232 / 255)
    static let secondary = Color(red: 173 / 255, green: 167 / 255, blue: 184 / 255)
}

/// Original Figma lettering and pin, with their exported proportions preserved.
struct PopinWordmark: View {
    var width: CGFloat = 94

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image("PopinLettering")
                .resizable()
                .frame(width: width, height: width * 131 / 364)
                .offset(y: width * 14 / 364)
            Image("PopinPin")
                .resizable()
                .frame(width: width * 89 / 364, height: width * 119 / 364)
                .offset(x: width * 76 / 364)
        }
        .frame(width: width, height: width * 145 / 364)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Popin")
    }
}

struct PopinButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(PopinTheme.background)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(PopinTheme.lilac, in: Capsule())
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// A typographic event cover, drawn natively so it stays crisp at every size.
extension InvitePalette {
    var color: Color {
        switch self {
        case .lilac: PopinTheme.lilac
        case .peach: Color(red: 0.97, green: 0.72, blue: 0.59)
        case .mint: Color(red: 0.66, green: 0.84, blue: 0.73)
        }
    }
}

struct InviteArtwork: View {
    var design = InviteDesign()
    var game = "VALORANT"
    var portrait = false

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack {
                design.palette.color
                switch design.layout {
                case .bold: bold(width: width)
                case .social: social(width: width)
                case .ticket: ticket(width: width)
                }
            }
            .foregroundStyle(PopinTheme.background)
        }
        .aspectRatio(portrait ? 0.8 : 1.15, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(design.mood.rawValue). You're invited. \(game). \(design.layout.rawValue) cover.")
    }

    private func headline(_ width: CGFloat, scale: CGFloat = 0.27) -> some View {
        Text(design.mood.headline)
            .font(.system(size: width * (design.mood == .goodCompany ? scale * 0.72 : scale), weight: .black, design: .rounded))
            .tracking(-width * 0.012)
            .lineSpacing(-width * 0.055)
            .fixedSize()
    }

    private func bold(width: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Ellipse()
                .stroke(.black.opacity(0.12), lineWidth: 1)
                .frame(width: width * 0.88, height: width * 0.56)
                .rotationEffect(.degrees(-38))
                .offset(x: width * 0.43, y: width * 0.3)
            headline(width)
                .offset(x: 22, y: portrait ? width * 0.35 : width * 0.15)
            Image("PopinPin")
                .resizable().scaledToFit()
                .frame(width: width * 0.24)
                .rotationEffect(.degrees(14))
                .offset(x: width * 0.68, y: portrait ? width * 0.7 : width * 0.37)
            Text("YOU’RE\nINVITED")
                .font(.system(size: width * 0.035, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.horizontal, width * 0.055)
                .padding(.vertical, width * 0.04)
                .background(PopinTheme.paper, in: RoundedRectangle(cornerRadius: 10))
                .rotationEffect(.degrees(10))
                .offset(x: width * 0.64, y: width * 0.13)
            coverFurniture
        }
    }

    private func social(width: CGFloat) -> some View {
        VStack(spacing: width * 0.06) {
            Text("YOUR PEOPLE ARE HERE")
                .font(.system(size: width * 0.028, weight: .bold, design: .monospaced))
                .tracking(1.5)
            Spacer(minLength: 0)
            Image("PopinPin").resizable().scaledToFit().frame(height: width * 0.2)
                .padding(width * 0.05)
                .background(PopinTheme.background, in: Circle())
            headline(width, scale: 0.23).multilineTextAlignment(.center)
            Spacer(minLength: 0)
            Text(game.uppercased()).font(.system(size: width * 0.03, weight: .bold, design: .monospaced)).tracking(2)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }

    private func ticket(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ADMIT YOU + YOUR PEOPLE")
                Spacer()
                Image(systemName: "sparkle")
            }
            .font(.system(size: width * 0.027, weight: .bold, design: .monospaced))
            Spacer(minLength: 0)
            headline(width, scale: 0.24)
            Text(game.uppercased())
                .font(.system(size: width * 0.03, weight: .bold, design: .monospaced)).tracking(1.5)
            Spacer(minLength: 0)
            Rectangle().fill(.black.opacity(0.3)).frame(height: 1)
            HStack(alignment: .bottom) {
                HStack(spacing: 3) {
                    ForEach(0..<28) { index in Rectangle().frame(width: index.isMultiple(of: 3) ? 3 : 1, height: width * 0.1) }
                }
                Spacer()
                Text("POPIN\nVOL. 01")
                    .font(.system(size: width * 0.025, weight: .bold, design: .monospaced))
            }
            .accessibilityHidden(true)
        }
        .padding(28)
        .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(.black.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [3, 5])).padding(10))
    }

    private var coverFurniture: some View {
        VStack {
            HStack {
                Text("THE WATCH PARTY")
                Spacer()
            }
            Spacer()
            HStack {
                Text(game.uppercased())
                Spacer()
                Text("VOL. 01 ↗")
            }
        }
        .font(.system(size: 10, weight: .bold, design: .monospaced))
        .tracking(1.5)
        .padding(24)
    }
}

/// Event-specific die cuts and artwork share a touch-driven reflective surface.
struct FoilStampSticker: View {
    let participation: Participation
    var game = "VALORANT"
    var eventTitle = "WATCH PARTY"
    var style: EventStampStyle = .angular
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var light = CGSize.zero

    private var colors: [Color] {
        switch style {
        case .angular: [Color(red: 0.70, green: 0.61, blue: 0.97), Color(red: 0.82, green: 0.94, blue: 0.99), Color(red: 0.95, green: 0.79, blue: 0.94), Color(red: 0.76, green: 0.73, blue: 0.99)]
        case .seal: [Color(red: 0.47, green: 0.79, blue: 0.66), Color(red: 0.91, green: 0.97, blue: 0.76), Color(red: 0.77, green: 0.92, blue: 0.85), Color(red: 0.52, green: 0.77, blue: 0.79)]
        case .ticket: [Color(red: 1, green: 0.69, blue: 0.39), Color(red: 1, green: 0.91, blue: 0.66), Color(red: 0.76, green: 0.88, blue: 0.98), Color(red: 0.95, green: 0.65, blue: 0.48)]
        }
    }

    private var edition: String { participation == .inPerson ? "IRL EXCLUSIVE" : "ONLINE EDITION" }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let cut = StampSilhouette(style: style)
            ZStack {
                cut.fill(LinearGradient(colors: colors,
                    startPoint: UnitPoint(x: 0.1 + light.width * 0.2, y: 0),
                    endPoint: UnitPoint(x: 0.9 + light.width * 0.2, y: 1)))
                artwork(width: width)
                    .foregroundStyle(PopinTheme.background)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                LinearGradient(stops: [.init(color: .clear, location: 0.15), .init(color: .white.opacity(0.7), location: 0.43), .init(color: .clear, location: 0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .offset(x: light.width * width * 0.55, y: light.height * 30)
                    .blendMode(.screen)
                    .allowsHitTesting(false)
            }
            .clipShape(cut)
            .overlay { cut.stroke(.white.opacity(0.85), lineWidth: 2).padding(1).allowsHitTesting(false) }
            .contentShape(cut)
            .rotation3DEffect(.degrees(reduceMotion ? 0 : Double(light.width) * 6), axis: (x: 0, y: 1, z: 0))
            .rotation3DEffect(.degrees(reduceMotion ? 0 : -Double(light.height) * 6), axis: (x: 1, y: 0, z: 0))
            .simultaneousGesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        light = CGSize(width: min(1, max(-1, value.location.x / width * 2 - 1)), height: min(1, max(-1, value.location.y / geometry.size.height * 2 - 1)))
                    }
                    .onEnded { _ in
                        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.45)) { light = .zero }
                    }
            )
        }
        .aspectRatio(style.aspectRatio, contentMode: .fit)
        .shadow(color: .black.opacity(0.18), radius: 4, x: 2, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Reflective \(eventTitle) \(style.rawValue) stamp. \(edition).")
    }

    @ViewBuilder private func artwork(width: CGFloat) -> some View {
        switch style {
        case .angular:
            VStack(spacing: width * 0.035) {
                HStack {
                    Text("POPIN")
                    Spacer()
                    Image(systemName: "sparkle")
                }
                .font(.system(size: width * 0.035, weight: .bold, design: .monospaced))
                Spacer(minLength: 0)
                Image("PopinPin").resizable().scaledToFit().frame(height: width * 0.36)
                gameLabel(width: width, scale: 0.10)
                titleLabel(width: width)
                Spacer(minLength: 0)
                Text(edition)
                    .font(.system(size: width * 0.034, weight: .bold, design: .monospaced))
                    .tracking(1)
                    .padding(.vertical, width * 0.035)
                    .frame(maxWidth: .infinity)
                    .overlay(Capsule().strokeBorder(.black.opacity(0.3), lineWidth: 0.7))
            }
            .padding(width * 0.085)
        case .seal:
            ZStack {
                Circle().stroke(.black.opacity(0.3), lineWidth: 0.8).padding(width * 0.09)
                Circle().stroke(.black.opacity(0.15), style: StrokeStyle(lineWidth: 0.7, dash: [2, 3])).padding(width * 0.13)
                VStack(spacing: width * 0.024) {
                    Text("POPIN • LOCAL CREW")
                        .font(.system(size: width * 0.031, weight: .bold, design: .monospaced))
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: width * 0.19, weight: .medium))
                        .padding(.vertical, width * 0.015)
                    gameLabel(width: width, scale: 0.095)
                    titleLabel(width: width)
                    Text(edition)
                        .font(.system(size: width * 0.03, weight: .bold, design: .monospaced))
                }
                .padding(width * 0.19)
            }
        case .ticket:
            HStack(spacing: width * 0.045) {
                VStack(alignment: .leading, spacing: width * 0.025) {
                    Text("POPIN / ADMIT ONE")
                        .font(.system(size: width * 0.029, weight: .bold, design: .monospaced))
                    Spacer(minLength: 0)
                    gameLabel(width: width, scale: 0.075)
                    titleLabel(width: width)
                    Spacer(minLength: 0)
                    Text(edition)
                        .font(.system(size: width * 0.028, weight: .bold, design: .monospaced))
                }
                Rectangle().fill(.black.opacity(0.25)).frame(width: 0.7)
                VStack(spacing: width * 0.06) {
                    Image(systemName: "bolt.fill").font(.system(size: width * 0.14))
                    Image(systemName: "flag.checkered").font(.system(size: width * 0.1))
                }
                .frame(width: width * 0.19)
            }
            .padding(width * 0.11)
        }
    }

    private func gameLabel(width: CGFloat, scale: CGFloat) -> some View {
        Text(game.uppercased())
            .font(.system(size: width * scale, weight: .black, design: .rounded))
            .tracking(-0.5)
            .lineLimit(1)
            .minimumScaleFactor(0.45)
    }

    private func titleLabel(width: CGFloat) -> some View {
        Text(eventTitle.uppercased())
            .font(.system(size: width * 0.034, weight: .bold, design: .monospaced))
            .tracking(0.7)
            .multilineTextAlignment(style == .ticket ? .leading : .center)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
    }
}

private struct StampSilhouette: Shape {
    let style: EventStampStyle

    func path(in rect: CGRect) -> Path {
        switch style {
        case .seal:
            var path = Path()
            for step in 0...240 {
                let angle = Double(step) / 240 * .pi * 2
                let radius = min(rect.width, rect.height) * (0.48 + sin(angle * 20) * 0.02)
                let point = CGPoint(x: rect.midX + cos(angle) * radius, y: rect.midY + sin(angle) * radius)
                if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
            return path
        case .ticket:
            let corner = rect.width * 0.06
            let notch = rect.width * 0.045
            let w = rect.width, h = rect.height
            var path = Path()
            path.move(to: CGPoint(x: corner, y: 0))
            path.addLine(to: CGPoint(x: w - corner, y: 0))
            path.addQuadCurve(to: CGPoint(x: w, y: corner), control: CGPoint(x: w, y: 0))
            path.addLine(to: CGPoint(x: w, y: h / 2 - notch))
            path.addQuadCurve(to: CGPoint(x: w, y: h / 2 + notch), control: CGPoint(x: w - notch * 2, y: h / 2))
            path.addLine(to: CGPoint(x: w, y: h - corner))
            path.addQuadCurve(to: CGPoint(x: w - corner, y: h), control: CGPoint(x: w, y: h))
            path.addLine(to: CGPoint(x: corner, y: h))
            path.addQuadCurve(to: CGPoint(x: 0, y: h - corner), control: CGPoint(x: 0, y: h))
            path.addLine(to: CGPoint(x: 0, y: h / 2 + notch))
            path.addQuadCurve(to: CGPoint(x: 0, y: h / 2 - notch), control: CGPoint(x: notch * 2, y: h / 2))
            path.addLine(to: CGPoint(x: 0, y: corner))
            path.addQuadCurve(to: CGPoint(x: corner, y: 0), control: .zero)
            path.closeSubpath()
            return path
        case .angular:
            let cut = rect.width * 0.1
            var path = Path()
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: rect.maxX - cut, y: 0))
            path.addLine(to: CGPoint(x: rect.maxX, y: cut))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: cut, y: rect.maxY))
            path.addLine(to: CGPoint(x: 0, y: rect.maxY - cut))
            path.closeSubpath()
            return path
        }
    }
}

struct StampView: View {
    let participation: Participation
    var game = "VALORANT"
    var eventTitle = "WATCH PARTY"
    var style: EventStampStyle = .angular

    var body: some View {
        FoilStampSticker(participation: participation, game: game, eventTitle: eventTitle, style: style)
            .frame(maxWidth: 280)
            .rotationEffect(.degrees(-5))
            .padding(16)
            .frame(maxWidth: .infinity)
    }
}
