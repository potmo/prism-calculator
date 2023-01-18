import Foundation
import simd

typealias Point = SIMD3<Double>
typealias Vector = SIMD3<Double>
typealias FVector = SIMD3<Float>

extension Vector {
    func angleBetween(and other: Vector) -> Double {
        let planeNormal: Vector = [0, 0, 1]
        return atan2(self.normalized.cross(other.normalized).dot(planeNormal), self.normalized.dot(other.normalized))
    }
}

extension [Vector] {
    var average: Vector {
        let scale = 1.0 / Double(count)
        return self.reduce(Point(0.0, 0.0, 0.0)) { prev, curr in prev + curr }
            .scaled(by: scale)
    }
}

extension SIMD2<Double> {
    var vector: Vector {
        return Vector(self.x, self.y, 0)
    }
}

extension Vector {
    static var up: Vector {
        return Vector(x: 0, y: 1, z: 0)
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

extension Vector {
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

    var normalized: Vector {
        return simd_normalize(self)
    }

    var length: Double {
        return simd_length(self)
    }

    func cross(_ other: Vector) -> Vector {
        return simd_cross(self, other)
    }

    func dot(_ other: Vector) -> Double {
        return simd_dot(self, other)
    }
}

extension Vector {
    func toFixed(fractions: ClosedRange<Int> = 2 ... 4) -> String {
        return "(\(x.toFixed(fractions: fractions)), \(y.toFixed(fractions: fractions)), \(z.toFixed(fractions: fractions)))"
    }
}

extension Vector {
    var fvector: FVector {
        return SIMD3<Float>(x: Float(x), y: Float(y), z: Float(z))
    }
}

extension FVector {
    var dvector: Vector {
        return SIMD3<Double>(x: Double(x), y: Double(y), z: Double(z))
    }
}
