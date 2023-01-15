import Foundation
import simd
import SwiftUI

struct FlatView: View {
    private let indexOfRefractionInSilicaAt680nm = 1.4558
    private let indexOfRefractionInSilicaAt420nm = 1.4681

    @State private var incomingAngle = Vector(1, 0, 0)
    @State private var outgoingAngle = Vector(1, 0, 0)

    @State private var firstPrismNormal = Vector(-1, 0, 0)
    @State private var secondPrismNormal = Vector(1, 0, 0)

    @State private var firstPrismLength = Measurement(value: 200.0, unit: UnitLength.millimeters)
    @State private var secondPrismLength = Measurement(value: 200.0, unit: UnitLength.millimeters)
    @State private var prismThickness = Measurement(value: 50.0, unit: UnitLength.millimeters)

    @State private var eyeDistance = Measurement(value: 100.0, unit: UnitLength.millimeters)

    // visible light is 420 to 680 nm
    // fused silica: https://www.filmetrics.com/refractive-index-database/SiO2/Fused-Silica-Silica-Silicon-Dioxide-Thermal-Oxide-ThermalOxide
    @State private var outerRafractiveIndex = 1.000293
    @State private var innerRefractiveIndex = 1.52

    private let millimeterFormat = MeasurementFormatStyle(unit: UnitLength.millimeters)
    private let degreeFormat = MeasurementFormatStyle(unit: UnitAngle.degrees)
    private let numberFormat = FloatingPointFormatStyle<Double>(locale: Locale(identifier: "en-US"))

    func updatePrismAngles(incomingAngle: Vector, outgoingAngle: Vector) {
        // this doesnt really matter
        let center = Point(x: 0.0, y: 0.0, z: 0.0)

        let firstFaceMid: Point = center + Vector(-prismThickness.value / 2.0, 0.0, 0.0)
        let secondFaceMid: Point = center + Vector(prismThickness.value / 2.0, 0.0, 0.0)
        let origin: Point = firstFaceMid + (incomingAngle.negated * eyeDistance.value)

        let refractionPath = RefractionPath(origin: origin,
                                            incomingRay: incomingAngle,
                                            outgoingRay: outgoingAngle,
                                            innerRefractiveIndex: innerRefractiveIndex,
                                            outerRefractiveIndex: outerRafractiveIndex,
                                            firstFaceMid: firstFaceMid,
                                            secondFaceMid: secondFaceMid)

        if let first = refractionPath.first {
            self.firstPrismNormal = first.normal
        }

        if let second = refractionPath.second {
            self.secondPrismNormal = second.normal
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 1) {
                VStack {
                    HStack {
                        Text("Incoming Angle:")
                        VectorInput(vector: $incomingAngle)
                    }

                    HStack {
                        Text("Outgoing Angle:")
                        VectorInput(vector: $outgoingAngle)
                    }
                }
                .onChange(of: outgoingAngle) { outgoingAngle in
                    updatePrismAngles(incomingAngle: incomingAngle, outgoingAngle: outgoingAngle)
                }
                .onChange(of: incomingAngle) { incomingAngle in
                    updatePrismAngles(incomingAngle: incomingAngle, outgoingAngle: outgoingAngle)
                }

                HStack {
                    Text("First face angle:")
                    VectorInput(vector: $firstPrismNormal)
                }

                HStack {
                    Text("Second face angle:")
                    VectorInput(vector: $secondPrismNormal)
                }

                HStack {
                    Text("First face length:")
                    TextField("", value: $firstPrismLength, format: millimeterFormat)
                    Slider(value: $firstPrismLength.value, in: 0 ... 200)
                }

                HStack {
                    Text("Second face length:")
                    TextField("", value: $secondPrismLength, format: millimeterFormat)
                    Slider(value: $secondPrismLength.value, in: 0 ... 200)
                }

                HStack {
                    Text("Prism thickness:")
                    TextField("", value: $prismThickness, format: millimeterFormat)
                    Slider(value: $prismThickness.value, in: 0 ... 200)
                }

                HStack {
                    Text("Outer refractive index:")
                    TextField("", value: $outerRafractiveIndex, format: numberFormat)
                }

                HStack {
                    Text("Inner refractive index:")
                    TextField("", value: $innerRefractiveIndex, format: numberFormat)
                }
            }
            .padding(10)

            Canvas { context, size in

                let center = Vector(x: size.width / 2, y: size.height / 2, z: 0)

                let firstFaceMid = center + Vector(-prismThickness.value / 2, 0, 0)
                let secondFaceMid = center + Vector(prismThickness.value / 2, 0, 0)

                let quaterTurn = Quat(angle: .pi / 2, axis: Vector(0, 0, 1))
                let prismTopLeft = firstFaceMid + firstPrismNormal.rotated(by: quaterTurn).scaled(by: firstPrismLength.value / 2)
                let prismBottomLeft = firstFaceMid + firstPrismNormal.rotated(by: quaterTurn.opposite).scaled(by: firstPrismLength.value / 2)

                let prismTopRight = secondFaceMid + secondPrismNormal.rotated(by: quaterTurn.opposite).scaled(by: secondPrismLength.value / 2)
                let prismBottomRight = secondFaceMid + secondPrismNormal.rotated(by: quaterTurn).scaled(by: secondPrismLength.value / 2)

                var prismPath = Path()
                prismPath.move(to: prismTopLeft)
                prismPath.addLine(to: prismTopRight)
                prismPath.addLine(to: prismBottomRight)
                prismPath.addLine(to: prismBottomLeft)
                prismPath.closeSubpath()

                var firstFaceNormalPath = Path()
                firstFaceNormalPath.move(to: firstFaceMid + firstPrismNormal * 10)
                firstFaceNormalPath.addLine(to: firstFaceMid - firstPrismNormal * 5)

                var secondFaceNormalPath = Path()
                secondFaceNormalPath.move(to: secondFaceMid + secondPrismNormal * 10)
                secondFaceNormalPath.addLine(to: secondFaceMid - secondPrismNormal * 5)

                // let refractiveIndices: StrideTo<Double> = stride(from: indexOfRefractionInSilicaAt680nm, to: indexOfRefractionInSilicaAt420nm, by: 0.001)
                // let rayPaths = stride(from: -30.0, to: 30.0, by: 5.0).flatMap{offset in
                // return refractiveIndices.map{ innerRefractiveIndex -> Path in

                let offset = 0.0
                let origin = firstFaceMid + (incomingAngle.negated * eyeDistance.value + Vector(x: 0.0, y: 1.0, z: 0.0).scaled(by: offset * 2.0))

                let rayPath: Path = pathForRay(incommingRay: incomingAngle,
                                               origin: origin,
                                               innerRefractiveIndex: innerRefractiveIndex,
                                               outerRefractiveIndex: outerRafractiveIndex,
                                               firstFaceMid: firstFaceMid,
                                               firstFaceNormal: firstPrismNormal,
                                               secondFaceMid: secondFaceMid,
                                               secondFaceNormal: secondPrismNormal)
                let rayPaths = [rayPath]
                // }
                // }

                context.transform = CGAffineTransform(scaleX: 1, y: 1)
                context.stroke(prismPath, with: .color(.blue), style: StrokeStyle(lineWidth: 0.5))
                context.stroke(firstFaceNormalPath, with: .color(.gray), style: StrokeStyle(lineWidth: 0.5, dash: [1, 1]))
                context.stroke(secondFaceNormalPath, with: .color(.gray), style: StrokeStyle(lineWidth: 0.5, dash: [1, 1]))
                for rayPath in rayPaths {
                    context.stroke(rayPath, with: .color(.red.opacity(1.0)), style: StrokeStyle(lineWidth: 0.5))
                }
            }
            .background(content: { Color.white })
        }
    }

    func pathForRay(incommingRay: Vector,
                    origin: Point,
                    innerRefractiveIndex: Double,
                    outerRefractiveIndex: Double,
                    firstFaceMid: Point,
                    firstFaceNormal: Vector,
                    secondFaceMid: Point,
                    secondFaceNormal: Vector) -> Path {
        var path = Path()
        let refractionPath = RefractionPath(origin: origin,
                                            incomingRay: incommingRay,
                                            innerRefractiveIndex: innerRefractiveIndex,
                                            outerRefractiveIndex: outerRefractiveIndex,
                                            firstFaceMid: firstFaceMid,
                                            firstFaceNormal: firstFaceNormal,
                                            secondFaceMid: secondFaceMid,
                                            secondFaceNormal: secondFaceNormal)

        guard let first = refractionPath.first else {
            return path
        }

        path.addArc(center: first.origin,
                    radius: 3,
                    startAngle: 0,
                    endAngle: .pi * 2,
                    clockwise: true)

        path.move(to: first.origin)
        path.addLine(to: first.incidencePoint)

        guard let second = refractionPath.second else {
            return path
        }

        path.addLine(to: second.incidencePoint)
        path.addLine(to: second.incidencePoint + second.refractionVector * 100)

        return path
    }
}



extension Path {
    mutating func move(to point: Point) {
        self.move(to: point.cgPoint)
    }

    mutating func addLine(to point: Point) {
        self.addLine(to: point.cgPoint)
    }

    mutating func addArc(center: Point, radius: Double, startAngle: Double, endAngle: Double, clockwise: Bool) {
        self.addArc(center: center.cgPoint, radius: radius, startAngle: Angle(radians: startAngle), endAngle: Angle(radians: endAngle), clockwise: clockwise)
    }
}
