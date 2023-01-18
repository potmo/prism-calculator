import SceneKit
import SwiftUI

struct ContentView: View {
    @State private var view: Views = .multi
    var body: some View {
        VStack {
            Picker("View", selection: $view) {
                ForEach(Views.allCases) { view in
                    Text(view.rawValue.capitalized)
                }
            }
            switch view {
            case .flat:
                FlatView()
            case .single:
                SinglePrismView()
            case .multi:
                MultiPrismView()
            }
        }.pickerStyle(.segmented)
    }
}

enum Views: String, CaseIterable, Identifiable {
    var id: Self { self }

    case flat = "Flat"
    case single = "Single"
    case multi = "Multi"
}
