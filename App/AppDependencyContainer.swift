import SwiftUI
import Domain
import Data
import AIKit
import TimerKit
import Presentation

@MainActor
public final class AppDependencyContainer: ObservableObject {
    public let keyStore: APIKeyStoring
    public let selectedProvider: AIProvider = .gemini

    public init() {
        self.keyStore = KeychainService()
    }

    public func makeAIService() -> AIServiceProtocol {
        AIServiceFactory.make(provider: selectedProvider, keyStore: keyStore)
    }

    public func makeTimelineViewModel() -> TimelineViewModel {
        TimelineViewModel()
    }

    public func makeBrainDumpViewModel() -> BrainDumpViewModel {
        BrainDumpViewModel(aiService: makeAIService())
    }

    public func makeFocusTimerViewModel() -> FocusTimerViewModel {
        FocusTimerViewModel(durationMinutes: 25)
    }

    public func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(keyStore: keyStore)
    }
}
