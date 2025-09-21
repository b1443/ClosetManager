import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CameraView()
                .tabItem {
                    Label("Camera", systemImage: "camera.fill")
                }
            ClosetView()
                .tabItem {
                    Label("Closet", systemImage: "folder.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ClosetManager())
}
