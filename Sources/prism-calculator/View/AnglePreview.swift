import simd
import SwiftUI

struct AnglePreview: View {
    @Binding var angle: Measurement<UnitAngle>

    var body: some View {
        Canvas { context, size in

            let scale = 10.0
            let vector = angle.vector
            let center: SIMD3<Double> = [size.width, size.height, 0] / 2

            let front = center + vector * scale
            let back = center - vector * scale
            let left = front + simd_quatd(angle: -.pi * 0.8, axis: Vector(x: 0, y: 0, z: 1)).act(vector).scaled(by: scale * 0.5)
            let right = front + simd_quatd(angle: .pi * 0.8, axis: Vector(x: 0, y: 0, z: 1)).act(vector).scaled(by: scale * 0.5)

            var path = Path()

            path.move(to: back)
            path.addLine(to: front)
            path.move(to: left)
            path.addLine(to: front)
            path.addLine(to: right)

            context.stroke(path, with: .color(.red), style: .init(lineWidth: 1))

        }.frame(width: 30, height: 30)
    }
}

struct VectorPreview: View {
    @Binding var vector: Vector

    var body: some View {
        Canvas { context, size in

            let scale = 10.0
            let center: Vector = [size.width, size.height, 0.0] / 2.0

            let front = center + vector * scale
            let back = center - vector * scale
            let left = front + simd_quatd(angle: -.pi * 0.8, axis: Vector(x: 0.0, y: 0.0, z: 1.0)).act(vector).scaled(by: scale * 0.5)
            let right = front + simd_quatd(angle: .pi * 0.8, axis: Vector(x: 0.0, y: 0.0, z: 1.0)).act(vector).scaled(by: scale * 0.5)

            var path = Path()

            path.move(to: back)
            path.addLine(to: front)
            path.move(to: left)
            path.addLine(to: front)
            path.addLine(to: right)

            context.stroke(path, with: .color(.blue), style: .init(lineWidth: 1))

        }.frame(width: 30, height: 30)
    }
}
