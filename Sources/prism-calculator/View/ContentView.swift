import SceneKit
import SwiftUI

struct ContentView: View {
    @State private var show3d = true
    var body: some View {
        VStack {
            Button("Swap") {
                show3d.toggle()
            }
            if show3d {
                SinglePrismView()
            } else {
                FlatView()
            }
        }
    }
}
