import SwiftUI

struct PointInput: View {
    @Binding var vector: Vector
    let range: ClosedRange<Double>

    init(vector: Binding<Vector>, range: ClosedRange<Double>) {
        self._vector = vector
        self.range = range
    }

    private var meterFormat: FloatingPointFormatStyle<Double> {
        FloatingPointFormatStyle<Double>()
            .precision(.fractionLength(3 ... 3))
            .locale(Locale(identifier: "en-ud"))
    }

    var body: some View {
        HStack {
            
            Text("X")
            Slider(value: $vector.x, in: range)
            TextField("", value: $vector.x, format: meterFormat)

            Text("Y")
            Slider(value: $vector.y, in: range)
            TextField("", value: $vector.y, format: meterFormat)

            Text("Z")
            Slider(value: $vector.z, in: range)
            TextField("", value: $vector.z, format: meterFormat)
        }
    }
}
