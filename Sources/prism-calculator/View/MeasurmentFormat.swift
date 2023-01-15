import Foundation

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
