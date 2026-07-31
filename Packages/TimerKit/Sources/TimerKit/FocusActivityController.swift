import Foundation

#if canImport(ActivityKit) && os(iOS)
import ActivityKit

public struct FocusActivityAttributes: ActivityAttributes, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        public var endDate: Date
        public var isPaused: Bool

        public init(endDate: Date, isPaused: Bool) {
            self.endDate = endDate
            self.isPaused = isPaused
        }
    }

    public var blockTitle: String

    public init(blockTitle: String) {
        self.blockTitle = blockTitle
    }
}
#endif

@MainActor
public final class FocusActivityController {
    #if canImport(ActivityKit) && os(iOS)
    private var activity: Activity<FocusActivityAttributes>?
    #endif

    public init() {}

    public func start(title: String, endDate: Date) {
        #if canImport(ActivityKit) && os(iOS)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attrs = FocusActivityAttributes(blockTitle: title)
        let state = FocusActivityAttributes.ContentState(endDate: endDate, isPaused: false)
        do {
            activity = try Activity.request(
                attributes: attrs,
                content: .init(state: state, staleDate: endDate)
            )
        } catch {
            // Activity creation failed or not supported in current environment
        }
        #endif
    }

    public func pause(currentRemainingDate: Date) {
        #if canImport(ActivityKit) && os(iOS)
        guard let activity = self.activity else { return }
        let state = FocusActivityAttributes.ContentState(endDate: currentRemainingDate, isPaused: true)
        let content = ActivityContent(state: state, staleDate: nil)
        Task {
            await activity.update(content)
        }
        #endif
    }

    public func end() {
        #if canImport(ActivityKit) && os(iOS)
        guard let activity = self.activity else { return }
        self.activity = nil
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        #endif
    }
}
