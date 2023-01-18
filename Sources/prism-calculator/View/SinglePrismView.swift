import CameraControlARView
import Foundation
import RealityKit
import SwiftUI

struct SinglePrismView: View {
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
