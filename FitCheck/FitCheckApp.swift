import SwiftUI
import FirebaseCore

@main
struct FitCheckApp: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
