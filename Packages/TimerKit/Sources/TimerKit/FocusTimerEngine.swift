import Foundation

public actor FocusTimerEngine {
    public private(set) var remainingSeconds: Int
    public private(set) var isRunning: Bool = false
    private var task: Task<Void, Never>?
    private let onTick: @Sendable (Int) -> Void
    private let onFinish: @Sendable () -> Void

    public init(
        duration: Int,
        onTick: @escaping @Sendable (Int) -> Void,
        onFinish: @escaping @Sendable () -> Void = {}
    ) {
        self.remainingSeconds = duration
        self.onTick = onTick
        self.onFinish = onFinish
    }

    public func start() {
        guard !isRunning, remainingSeconds > 0 else { return }
        isRunning = true
        task?.cancel()
        task = Task {
            while remainingSeconds > 0, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                remainingSeconds -= 1
                onTick(remainingSeconds)
            }
            if remainingSeconds == 0 {
                isRunning = false
                onFinish()
            }
        }
    }

    public func pause() {
        task?.cancel()
        task = nil
        isRunning = false
    }

    public func reset(to newDuration: Int) {
        pause()
        remainingSeconds = newDuration
        onTick(remainingSeconds)
    }
}
