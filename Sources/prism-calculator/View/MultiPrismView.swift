import CameraControlARView
import Foundation
import RealityKit
import SwiftUI

struct MultiPrismView: View {
    @State private var rootAnchor = AnchorEntity()

    @State private var eyePosition = Point(0, 0, 3)

    @StateObject private var view: CameraControlARView = {
        let view = CameraControlARView(frame: .zero)
        return view
    }()

    var body: some View {
        VStack {
            ARViewContainer(view: view)
                .onAppear {
                    view.scene.addAnchor(rootAnchor)
                    self.updateModels(in: view)
                }
        }
    }

    func updateModels(in view: CameraControlARView) {
        let prismBoardCenter = Point(0, 0, 0)

        let silhouettes: [[simd_double2]] = [
            [
                [-1, 1],
                [0, 1],
                [0, 0],
                [-1, 0],
            ],
            [
                [0, 1],
                [1, 1],
                [1, 0],
                [0, 0],
            ],
            [
                [1, 1],
                [2, 1],
                [2, 0],
                [1, 0],
            ],
        ]

        let imageSections = silhouettes.map { silhouette in ImageSection(silhouette: silhouette, hitCenter: Point(0, 0, -3)) }

        let outerRefractiveIndex = 1.000293
        let innerRefractiveIndex = 1.52

        let generalDirection: Vector = [0, 0, 1]

        for imageSection in imageSections {
            let firstFace = FaceConfiguration(indexOfRefraction: outerRefractiveIndex / innerRefractiveIndex)
            let secondFace = FaceConfiguration(indexOfRefraction: innerRefractiveIndex / outerRefractiveIndex)
            let prismConfiguration = PrismConfiguration(position: imageSection.pivotPoint(relativeTo: prismBoardCenter, axis: generalDirection),
                                                        generalDirection: generalDirection,
                                                        thickness: 0.5,
                                                        silhouette: imageSection.silhouette(relativeTo: prismBoardCenter, axis: generalDirection),
                                                        firstFace: firstFace,
                                                        secondFace: secondFace)
            let setup = Setup(rayStartPosition: eyePosition,
                              rayEndPosition: imageSection.hitCenter,
                              prismConfiguration: prismConfiguration)

            let prismModel = Models.constructPrism(setup.prism)
            let rayModel = Models.constructRay(from: setup, hitRadius: 0.1, emergenceLength: 3.0)

            rootAnchor.addChild(prismModel)
            rootAnchor.addChild(rayModel)
        }

        let axisModel = Models.constructWorldOrigin()
        rootAnchor.addChild(axisModel)
    }
}
