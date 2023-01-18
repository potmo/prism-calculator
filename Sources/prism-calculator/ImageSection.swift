import Foundation
import simd

struct ImageSection {
    // TODO: These should be in image coordinates and have a board it fits on and scales
    let silhouette: [simd_double2]
    let hitCenter: Vector

    func pivotPoint(relativeTo point: Point, axis: Vector) -> Point {
        let right = Vector.up.cross(axis)
        let up = axis.cross(right)

        return silhouette.map(\.vector)
            .map { right.scaled(by: $0.x) + up.scaled(by: $0.y) }
            .average - point
    }

    func silhouette(relativeTo point: Point, axis: Vector) -> [simd_double2] {
        let right = axis.cross(.up)
        let up = right.cross(axis)

        let pivot = self.pivotPoint(relativeTo: point, axis: axis)
        return silhouette.map(\.vector)
            .map { $0 - pivot }
            .map { point in
                let x = point.dot(right)
                let y = point.dot(up)
                return simd_double2(x: x, y: y)
            }
    }
}
