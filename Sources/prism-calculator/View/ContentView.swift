import Foundation
import simd
import SwiftUI

typealias Point = SIMD3<Double>
typealias Vector = SIMD3<Double>
typealias Quat = simd_quatd

struct ContentView: View {
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

precedencegroup ExponentiativePrecedence {
    associativity: right
    higherThan: MultiplicationPrecedence
}

infix operator ^: ExponentiativePrecedence

func ^ (num: Double, power: Double) -> Double {
    return pow(num, power)
}

extension Vector {
    func angleBetween(and other: Vector) -> Double {
        let planeNormal: Vector = [0, 0, 1]
        return atan2(self.normalized.cross(other.normalized).dot(planeNormal), self.normalized.dot(other.normalized))
    }
}

extension Vector {
    func rotated(by quat: Quat) -> Vector {
        return quat.act(self)
    }
}

extension Vector {
    init(_ x: Double, _ y: Double, _ z: Double) {
        self.init(x: x, y: y, z: z)
    }
}

extension simd_quatd {
    var opposite: simd_quatd {
        return self * simd_quatd(angle: .pi, axis: [0, 0, 1])
    }

    var vector: SIMD3<Double> {
        return self.act([1, 0, 0])
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

extension SIMD3 where Scalar == Double {
    var cgPoint: CGPoint {
        return CGPoint(x: x, y: y)
    }
}

extension Vector {
    var negated: Vector {
        return self * -1
    }

    func scaled(by value: Double) -> Vector {
        return self * value
    }

    var normalized: SIMD3<Scalar> {
        return simd_normalize(self)
    }

    var length: Scalar {
        return simd_length(self)
    }

    func cross(_ other: SIMD3<Scalar>) -> SIMD3<Scalar> {
        return simd_cross(self, other)
    }

    func dot(_ other: SIMD3<Scalar>) -> Scalar {
        return simd_dot(self, other)
    }
}

extension Double {
    var degrees: Double {
        self * 360 / (.pi * 2)
    }

    var radians: Double {
        self * .pi * 2 / 360
    }
}

extension Vector {
    func toFixed(fractions: ClosedRange<Int> = 2 ... 4) -> String {
        return "(\(x.toFixed(fractions: fractions)), \(y.toFixed(fractions: fractions)), \(z.toFixed(fractions: fractions)))"
    }
}

extension Double {
    func toFixed(fractions: ClosedRange<Int> = 2 ... 4) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en-US")
        formatter.numberStyle = NumberFormatter.Style.decimal
        formatter.roundingMode = NumberFormatter.RoundingMode.halfUp
        formatter.minimumFractionDigits = fractions.lowerBound
        formatter.maximumFractionDigits = fractions.upperBound

        return formatter.string(for: self) ?? "N/A"
    }
}

struct MeasurementFormatStyle<UnitType: Unit>: ParseableFormatStyle {
    typealias FormatInput = Measurement<UnitType>
    typealias FormatOutput = String

    typealias Strategy = MeasurmentParseStrategy<UnitType>

    private let unit: UnitType
    init(unit: UnitType) {
        self.unit = unit
    }

    func format(_ measurment: Measurement<UnitType>) -> String {
        let formatter = MeasurementFormatter()

        let numberFormatter = NumberFormatter()

        numberFormatter.locale = Locale(identifier: "en_US")
        numberFormatter.alwaysShowsDecimalSeparator = true
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2

        formatter.numberFormatter = numberFormatter
        formatter.unitStyle = .short
        formatter.unitOptions = .providedUnit

        let string = formatter.string(from: measurment)
        return string
    }

    var parseStrategy: MeasurmentParseStrategy<UnitType> {
        return MeasurmentParseStrategy<UnitType>(unit: self.unit)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(unit.symbol)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self.unit = UnitType(symbol: value)
    }
}

struct MeasurmentParseStrategy<UnitType: Unit>: ParseStrategy {
    public typealias ParseInput = String
    public typealias ParseOutput = Measurement<UnitType>
    private let unit: UnitType

    init(unit: UnitType) {
        self.unit = unit
    }

    func parse(_ value: ParseInput) throws -> ParseOutput {
        let floatingPoint = FloatingPointParseStrategy(format: FloatingPointFormatStyle<Double>.number, lenient: false)
        let number = try floatingPoint.parse(value)
        return Measurement(value: number, unit: self.unit)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(unit.symbol)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self.unit = UnitType(symbol: value)
    }
}
