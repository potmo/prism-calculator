import Foundation
import CameraControlARView
import SwiftUI

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
