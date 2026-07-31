import SwiftUI
import SwiftData
import Data

@main
struct FocalApp: App {
    @StateObject private var container = AppDependencyContainer()

    var body: some Scene {
        WindowGroup {
            MainTabView(container: container)
                .modelContainer(SwiftDataStack.container)
        }
    }
}
