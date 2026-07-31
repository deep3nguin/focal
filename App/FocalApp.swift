import SwiftUI
import SwiftData
import Data

public struct FocalApp: App {
    @StateObject private var container = AppDependencyContainer()

    public init() {}

    public var body: some Scene {
        WindowGroup {
            MainTabView(container: container)
                .modelContainer(SwiftDataStack.container)
        }
    }
}
