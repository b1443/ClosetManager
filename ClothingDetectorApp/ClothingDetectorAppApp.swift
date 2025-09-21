import SwiftUI

@main
struct ClothingDetectorAppApp: App {
    @StateObject private var closetManager = ClosetManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(closetManager)
        }
    }
}
