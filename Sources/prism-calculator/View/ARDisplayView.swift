import CameraControlARView
import Foundation
import RealityKit
import SwiftUI

struct ARDisplayView: View {
    @State private var rootAnchor = AnchorEntity()

    @State private var start = Point(0, 0, 3)
    @State private var end = Point(0, 0, -3)

    @State private var outgoingAngle = Vector(1, 0, 0)
    @StateObject private var view: CameraControlARView = {
        let view = CameraControlARView(frame: .zero)
        return view
    }()

    private var meterFormat: FloatingPointFormatStyle<Double> {
        FloatingPointFormatStyle<Double>()
            .precision(.fractionLength(3 ... 3))
            .locale(Locale(identifier: "en-ud"))
    }

    var body: some View {
        VStack {
            HStack {
                Text("Start")
                PointInput(vector: $start, range: -4.0 ... 4.0)
            }

            HStack {
                Text("End")
                PointInput(vector: $end, range: -4.0 ... 4.0)
            }

            ARViewContainer(view: view)
                .onAppear {
                    Self.updateModels(in: view, rayStart: start, rayEnd: end)
                }
                .onChange(of: start) { rayStart in
                    Self.updateModels(in: view, rayStart: rayStart, rayEnd: end)
                }
                .onChange(of: end) { rayEnd in
                    Self.updateModels(in: view, rayStart: start, rayEnd: rayEnd)
                }
        }
    }

    static func updateModels(in view: CameraControlARView, rayStart: Point, rayEnd: Point) {
        let rootName = "root"
        view.scene.anchors.filter { $0.name == rootName }.forEach { $0.removeFromParent() }

        let rootAnchor = AnchorEntity()
        rootAnchor.name = rootName
        view.scene.addAnchor(rootAnchor)

        let outerRefractiveIndex = 1.000293
        let innerRefractiveIndex = 1.52
        let prismConfig = PrismConfiguration(position: [0, 0, 0],
                                             generalDirection: [0, 0, 1],
                                             thickness: 0.5,
                                             firstFace: FaceConfiguration(width: 1,
                                                                          height: 1,
                                                                          indexOfRefraction: outerRefractiveIndex / innerRefractiveIndex),
                                             secondFace: FaceConfiguration(width: 1,
                                                                           height: 1,
                                                                           indexOfRefraction: innerRefractiveIndex / outerRefractiveIndex))

        let setup = Setup(rayStartPosition: rayStart,
                          rayEndPosition: rayEnd,
                          prismConfiguration: prismConfig)

        let prism = setup.prism

        let prismModel = Models.constructPrism(prism)
        let rayModel = Models.constructRay(from: setup, hitRadius: 0.1, emergenceLength: 3.0)
        let axisModel = Models.constructWorldOrigin()

        rootAnchor.addChild(prismModel)
        rootAnchor.addChild(rayModel)
        rootAnchor.addChild(axisModel)
    }
}

struct ARViewContainer: NSViewRepresentable {
    typealias NSViewType = CameraControlARView

    let view: CameraControlARView

    init(view: CameraControlARView) {
        self.view = view
    }

    func makeNSView(context: Context) -> CameraControlARView {
        return view
    }

    func updateNSView(_ nsView: CameraControlARView, context: Context) {
    }
}

struct Vertice {
    let position: Point
    let index: UInt32
}

enum Models {
    static func constructWorldOrigin() -> Entity {
        let scale: Float = 0.1
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

            let angle: Double = -.pi * 2.0 * line / 360.0
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

        return Self.rayModelFromVertices(lines: lines)
    }

    static func constructRay(_ prism: Prism, rayStart: Point) -> ModelEntity {
        let rayRadius = 0.05

        var i: UInt32 = 0

        let lines: [[Vertice]] = stride(from: 0.0, through: 360.0, by: 360 / 20).map { line in

            let angle: Double = -.pi * 2.0 * line / 360.0
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

        return Self.rayModelFromVertices(lines: lines)
    }

    private static func rayModelFromVertices(lines: [[Vertice]]) -> ModelEntity {
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
                triangleIndices.append(bottomLeft)
                triangleIndices.append(bottomRight)
                triangleIndices.append(topLeft)

                // secon triangle
                triangleIndices.append(topLeft)
                triangleIndices.append(bottomRight)
                triangleIndices.append(topRight)
            }
        }

        var descriptor = MeshDescriptor(name: "ray")
        let floatPositions: [simd_float3] = positions.map(\.fvector).map { [$0.x, $0.y, $0.z] }
        descriptor.positions = MeshBuffer(floatPositions)
        descriptor.primitives = .triangles(triangleIndices)

        var material = PhysicallyBasedMaterial()
        material.baseColor = PhysicallyBasedMaterial.BaseColor(tint: .red)
        material.roughness = 1.0
        material.metallic = 0.0
        material.blending = .opaque
        material.faceCulling = .none
        material.sheen = .none
        let mesh = try! MeshResource.generate(from: [descriptor])

        let model = ModelEntity(mesh: mesh, materials: [material])

        return model
    }

    static func constructPrism(_ prism: Prism) -> ModelEntity {
        var positions: [Vector] = []
        var triangleIndices: [UInt32] = []

        positions.append(prism.firstFace.bottomLeft)
        positions.append(prism.firstFace.bottomRight)
        positions.append(prism.firstFace.topLeft)
        positions.append(prism.firstFace.topRight)

        positions.append(prism.secondFace.bottomRight)
        positions.append(prism.secondFace.bottomLeft)
        positions.append(prism.secondFace.topRight)
        positions.append(prism.secondFace.topLeft)

        // Front Triangle 1
        triangleIndices.append(0)
        triangleIndices.append(1)
        triangleIndices.append(2)

        // Front Triangle 2
        triangleIndices.append(2)
        triangleIndices.append(1)
        triangleIndices.append(3)

        // Back Triangle 1
        triangleIndices.append(5)
        triangleIndices.append(4)
        triangleIndices.append(7)

        // Back Triangle 2
        triangleIndices.append(7)
        triangleIndices.append(4)
        triangleIndices.append(6)

        // Right Triangle 1
        triangleIndices.append(1)
        triangleIndices.append(5)
        triangleIndices.append(3)

        // Right Triangle 2
        triangleIndices.append(3)
        triangleIndices.append(5)
        triangleIndices.append(7)

        // Left Triangle 1
        triangleIndices.append(4)
        triangleIndices.append(0)
        triangleIndices.append(6)

        // Left Triangle 2
        triangleIndices.append(6)
        triangleIndices.append(0)
        triangleIndices.append(2)

        // Bottom Triangle 1
        triangleIndices.append(4)
        triangleIndices.append(5)
        triangleIndices.append(0)

        // Bottom Triangle 2
        triangleIndices.append(0)
        triangleIndices.append(5)
        triangleIndices.append(1)

        // Top Triangle 1
        triangleIndices.append(2)
        triangleIndices.append(3)
        triangleIndices.append(6)

        // Top Triangle 2
        triangleIndices.append(6)
        triangleIndices.append(3)
        triangleIndices.append(7)

        var descriptor = MeshDescriptor(name: "prism")
        let floatPositions: [simd_float3] = positions.map(\.fvector).map { [$0.x, $0.y, $0.z] }
        descriptor.positions = MeshBuffer(floatPositions)
        descriptor.primitives = .triangles(triangleIndices)

        var material = PhysicallyBasedMaterial()
        material.baseColor = PhysicallyBasedMaterial.BaseColor(tint: .blue)
        material.roughness = 1.0
        material.metallic = 0.0
        material.blending = .transparent(opacity: 0.2)
        material.faceCulling = .none
        material.sheen = .none

        let mesh = try! MeshResource.generate(from: [descriptor])

        let model = ModelEntity(mesh: mesh, materials: [material])

        return model
    }
}
