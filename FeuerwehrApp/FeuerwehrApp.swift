import SwiftUI

@main
struct FeuerwehrApp: App {
    @State private var feuerwehren: [Feuerwehr] = DataManager.shared.loadFeuerwehren()
    
    var body: some Scene {
        WindowGroup {
            FeuerwehrView()
        }
    }
}
