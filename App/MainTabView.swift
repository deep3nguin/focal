import SwiftUI
import DesignSystem
import Presentation

public struct MainTabView: View {
    @StateObject private var container: AppDependencyContainer

    public init(container: AppDependencyContainer) {
        _container = StateObject(wrappedValue: container)
    }

    public var body: some View {
        TabView {
            TimelineView(viewModel: container.makeTimelineViewModel())
                .tabItem {
                    Label("Timeline", systemImage: "calendar.day.timeline.left")
                }

            BrainDumpView(viewModel: container.makeBrainDumpViewModel())
                .tabItem {
                    Label("Brain Dump", systemImage: "brain.head.profile")
                }

            FocusTimerView(viewModel: container.makeFocusTimerViewModel())
                .tabItem {
                    Label("Focus", systemImage: "timer")
                }

            SettingsView(viewModel: container.makeSettingsViewModel())
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(FocalColors.primaryAccent)
    }
}
