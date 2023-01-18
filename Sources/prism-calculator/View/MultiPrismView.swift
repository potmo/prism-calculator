import CameraControlARView
import Foundation
import RealityKit
import SwiftUI

struct MultiPrismView: View {
    @State private var rootAnchor = AnchorEntity()

    @State private var start = Point(0, 0, 3)
    @State private var end = Point(0, 0, -3)

    @State private var outgoingAngle = Vector(1, 0, 0)
    @StateObject private var view: CameraControlARView = {
        let view = CameraControlARView(frame: .zero)
        return view
    }()



    var body: some View {
        VStack {


            ARViewContainer(view: view)
                .onAppear {
                    Self.updateModels(in: view, rayStart: start, rayEnd: end)
                }

        }
    }

    static func updateModels(in view: CameraControlARView, rayStart: Point, rayEnd: Point) {

    }
}

