import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "figure.run")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("FitCheck")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            .padding()
            .navigationTitle("FitCheck")
        }
    }
}

#Preview {
    ContentView()
}
