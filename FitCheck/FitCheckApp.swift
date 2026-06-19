import SwiftUI
import FirebaseCore

@main
struct FitCheckApp: App {
    @StateObject private var session: SessionManager
    @StateObject private var authVM: AuthViewModel

    init() {
        FirebaseApp.configure()
        // Build the object graph once so SessionManager can be passed into AuthViewModel.
        let session = SessionManager()
        let authVM  = AuthViewModel(session: session)
        _session = StateObject(wrappedValue: session)
        _authVM  = StateObject(wrappedValue: authVM)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
                .environmentObject(authVM)
        }
    }
}
