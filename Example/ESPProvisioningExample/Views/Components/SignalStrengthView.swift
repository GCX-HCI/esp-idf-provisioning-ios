import SwiftUI

struct SignalStrengthView: View {
    let rssi: Int

    var body: some View {
        let active = Color.primary
        let inactive = Color.primary.opacity(0.2)
        GeometryReader { geometry in
            let radius = min(geometry.size.height, geometry.size.width)  / 2.0
            ArcSegment(radiusStart: radius, radiusEnd: radius * 0.825)
                .fill(rssi > -50 ? active : inactive)
            ArcSegment(radiusStart: radius * 0.7, radiusEnd: radius * 0.525)
                .fill(rssi > -60 ? active : inactive)
            ArcSegment(radiusStart: radius * 0.4, radiusEnd: radius * 0.225)
                .fill(rssi > -67 ? active : inactive)
            ArcSegment(radiusStart: radius * 0.1, radiusEnd: radius * 0.0)
                .fill()
        }
        .frame(maxWidth: 50, maxHeight: 50)
    }
}

extension SignalStrengthView {
    private struct Arc: Shape {
        var startAngle: Angle
        var endAngle: Angle
        var clockwise: Bool

        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
            return path
        }
    }

    private struct ArcSegment: Shape {
        let radiusStart: Double
        let radiusEnd: Double
        let angle = 45.0

        func path(in rect: CGRect) -> Path {
            var path = Path()
            let width = rect.size.width
            let height = rect.size.height
            let center = CGPoint(x: width * 0.5, y: (height * 0.5) + (height * 0.25))
            path.addArc(center: center, radius: radiusStart, startAngle: .degrees(-angle), endAngle: .degrees(180 + angle), clockwise: true)
            path.addArc(center: center, radius: radiusEnd, startAngle: .degrees(180 + angle), endAngle: .degrees(-angle), clockwise: false)
            path.closeSubpath()

            return path
        }
    }
}

struct SignalStrengthView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SignalStrengthView(rssi: -80)
            List {
                HStack {
                    Text("My network")
                    Spacer()
                    SignalStrengthView(rssi: -50)
                }

                HStack {
                    Text("Wifi")
                    Spacer()
                    SignalStrengthView(rssi: -80)
                }

            }
        }
    }
}
