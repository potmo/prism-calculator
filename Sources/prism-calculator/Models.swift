import Foundation
import RealityKit
import simd
import SwiftUI

struct Vertice {
    let position: Point
    let index: UInt32
}

enum Models {
    static func constructWorldOrigin() -> Entity {
        let scale: Float = 0.3
        let x = ModelEntity(mesh: .generateBox(width: 1 * scale, height: 0.01 * scale, depth: 0.01 * scale), materials: [SimpleMaterial(color: .red, isMetallic: false)])
        let y = ModelEntity(mesh: .generateBox(width: 0.01 * scale, height: 1 * scale, depth: 0.01 * scale), materials: [SimpleMaterial(color: .green, isMetallic: false)])
        let z = ModelEntity(mesh: .generateBox(width: 0.01 * scale, height: 0.01 * scale, depth: 1 * scale), materials: [SimpleMaterial(color: .blue, isMetallic: false)])
        x.position = [0.5 * scale, 0, 0]
        y.position = [0, 0.5 * scale, 0]
        z.position = [0, 0, 0.5 * scale]

        let axis = Entity()
        axis.addChild(x)
        axis.addChild(y)
        axis.addChild(z)
        return axis
    }

    static func constructRay(from setup: Setup, hitRadius: Double, emergenceLength: Double) -> ModelEntity {
        let rayRadius = hitRadius

        var i: UInt32 = 0

        let lines: [[Vertice]] = stride(from: 0.0, through: 360.0, by: 360 / 20).map { line in

            let angle: Double = .pi * 2.0 * line / 360.0
            let perp = setup.prism.firstFace.normal.cross(.up) * rayRadius
            let hit = setup.prism.firstFace.pivot + Quat(angle: angle, axis: setup.prism.firstFace.normal).act(perp)

            let rayDirection = (hit - setup.incidenceRay.origin).normalized

            let expandedSetup = Setup(prism: setup.prism,
                                      rayStart: Ray(origin: setup.incidenceRay.origin, direction: rayDirection),
                                      emergenceLength: emergenceLength)

            let line = [
                expandedSetup.incidenceRay.origin,
                expandedSetup.refractionRay.origin,
                expandedSetup.emergenceRay.origin,
                expandedSetup.focalPoint,
            ].map { position in
                let vertice = Vertice(position: position, index: i)
                i = i + 1
                return vertice
            }

            return line
        }

        return Self.rayModelFromVertices(lines: lines, color: .red, opacity: 1.0)
    }

    static func constructRay(_ prism: Prism, rayStart: Point) -> ModelEntity {
        let rayRadius = 0.05

        var i: UInt32 = 0

        let lines: [[Vertice]] = stride(from: 0.0, through: 360.0, by: 360 / 20).map { line in

            let angle: Double = .pi * 2.0 * line / 360.0
            let perp = prism.firstFace.normal.cross(.up) * rayRadius
            let hit = prism.firstFace.pivot + Quat(angle: angle, axis: prism.firstFace.normal).act(perp)

            let rayDirection = (rayStart - hit).normalized

            let refractionPath = RefractionPath(origin: rayStart,
                                                incomingRay: -rayDirection,
                                                innerRefractiveIndex: 1.52,
                                                outerRefractiveIndex: 1.000293,
                                                firstFaceMid: prism.firstFace.pivot,
                                                firstFaceNormal: prism.firstFace.normal,
                                                secondFaceMid: prism.secondFace.pivot,
                                                secondFaceNormal: prism.secondFace.normal)

            guard let first = refractionPath.first, let second = refractionPath.second else {
                return []
            }

            let line = [
                first.origin,
                first.incidencePoint,
                second.origin,
                second.incidencePoint,
                second.incidencePoint + second.incidenceVector * 4,
            ].map { position in
                let vertice = Vertice(position: position, index: i)
                i = i + 1
                return vertice
            }

            return line
        }

        return Self.rayModelFromVertices(lines: lines, color: .red, opacity: 1.0)
    }

    private static func rayModelFromVertices(lines: [[Vertice]], color: NSColor, opacity: Double) -> ModelEntity {
        var triangleIndices: [UInt32] = []
        var positions: [Vector] = []
        for line in lines {
            for point in line {
                positions.append(point.position)
            }
        }

        guard let firstLine = lines.first else {
            fatalError("there needs to be at least one line")
        }
        // for each section
        for s in 0 ..< (firstLine.endIndex - 1) {
            // for each line
            for l in lines.indices {
                let bottomLeft = lines[l][s].index
                let bottomRight = lines[(l + 1) % lines.count][s].index
                let topLeft = lines[l][s + 1].index
                let topRight = lines[(l + 1) % lines.count][s + 1].index

                // first triangle
                triangleIndices.append(topLeft)

                triangleIndices.append(bottomRight)
                triangleIndices.append(bottomLeft)

                // second triangle
                triangleIndices.append(topRight)
                triangleIndices.append(bottomRight)

                triangleIndices.append(topLeft)
            }
        }

        let firstFaceVertices = lines.map(\.first!)
        let lastFaceVertices = lines.map(\.last!)

        // add first face cap (expecting there to be a start and end vertice)
        let firstMidPoint = firstFaceVertices.map(\.position).reduce(Vector(0, 0, 0), +) / Double(lines.count)
        positions.append(firstMidPoint)
        let secondMidPoint = lastFaceVertices.map(\.position).reduce(Vector(0, 0, 0), +) / Double(lines.count)
        positions.append(secondMidPoint)

        let topVerticeIndex = lines.flatMap { $0 }.map(\.index).max()!
        let firstMidIndex = topVerticeIndex + 1
        let secondMidIndex = topVerticeIndex + 2

        // add first cap
        for index in firstFaceVertices.indices {
            triangleIndices.append(firstFaceVertices[index].index)
            triangleIndices.append(firstFaceVertices[(index + 1) % firstFaceVertices.count].index)
            triangleIndices.append(firstMidIndex)
        }

        for index in firstFaceVertices.indices {
            triangleIndices.append(secondMidIndex)
            triangleIndices.append(lastFaceVertices[(index + 1) % lastFaceVertices.count].index)
            triangleIndices.append(lastFaceVertices[index].index)
        }

        var descriptor = MeshDescriptor(name: "ray")
        let floatPositions: [simd_float3] = positions.map(\.fvector).map { [$0.x, $0.y, $0.z] }
        descriptor.positions = MeshBuffer(floatPositions)
        descriptor.primitives = .triangles(triangleIndices)

        var material = PhysicallyBasedMaterial()
        material.baseColor = PhysicallyBasedMaterial.BaseColor(tint: color)
        material.roughness = 1.0
        material.metallic = 0.0
        if opacity >= 1 {
            material.blending = .opaque
        } else {
            material.blending = .transparent(opacity: .init(floatLiteral: Float(opacity)))
        }
        material.faceCulling = .back
        material.sheen = .none
        let mesh = try! MeshResource.generate(from: [descriptor])

        let model = ModelEntity(mesh: mesh, materials: [material])

        return model
    }

    static func constructPrism(_ prism: Prism) -> ModelEntity {
        let prismDirection = (prism.firstFace.pivot - prism.secondFace.pivot).normalized
        let right = Vector.up.cross(prismDirection)
        let up = prismDirection.cross(right)

        let lines: [[Vertice]] = prism.silhouette.enumerated().map { (index: Int, point: SIMD2<Double>) in

            let x: Vector = right * point.x
            let y: Vector = up * point.y
            let pointPosition = x + y
            let offset: Vector = prismDirection * 100.0
            let rayOrigin: Vector = prism.firstFace.pivot + pointPosition + offset
            let firstFaceHit = RefractionPath.intersectPlane(normal: prism.firstFace.normal,
                                                             planeOrigin: prism.firstFace.pivot,
                                                             rayOrigin: rayOrigin,
                                                             rayDirection: -prismDirection)

            let secondFaceHit = RefractionPath.intersectPlane(normal: -prism.secondFace.normal,
                                                              planeOrigin: prism.secondFace.pivot,
                                                              rayOrigin: rayOrigin,
                                                              rayDirection: -prismDirection)

            guard let firstFaceHit, let secondFaceHit else {
                fatalError("not possible to compute first or second face hits when constructing prism")
            }

            return [
                Vertice(position: firstFaceHit, index: UInt32(index * 2)),
                Vertice(position: secondFaceHit, index: UInt32(index * 2) + 1),
            ]
        }

        return Self.rayModelFromVertices(lines: lines, color: .blue, opacity: 0.2)
    }
}
