import Foundation
import simd
typealias Quat = simd_quatd

extension simd_quatd {
    var opposite: simd_quatd {
        return self * simd_quatd(angle: .pi, axis: [0, 0, 1])
    }

    var vector: SIMD3<Double> {
        return self.act([1, 0, 0])
    }
}
