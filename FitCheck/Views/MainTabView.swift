import SwiftUI

/// Root tab view shown to authenticated users. Placeholder tabs — replace with real views.
struct MainTabView: View {
    let user: FitCheckUser

    var body: some View {
        TabView {
            Text("Home")
                .tabItem { Label("Home", systemImage: "house") }

            Text("Profile — @\(user.username)")
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}
