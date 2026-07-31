import SwiftUI
import Domain
import DesignSystem
import TimerKit

@MainActor
@Observable
public final class FocusTimerViewModel {
    public var blockTitle: String = "Deep Focus Session"
    public var durationMinutes: Int = 25
    public var remainingSeconds: Int = 25 * 60
    public var isRunning: Bool = false

    private var engine: FocusTimerEngine?
    private let activityController = FocusActivityController()

    public init(durationMinutes: Int = 25) {
        self.durationMinutes = durationMinutes
        self.remainingSeconds = durationMinutes * 60
    }

    public func startTimer() {
        guard !isRunning else { return }
        isRunning = true

        let totalDuration = remainingSeconds
        let endDate = Date().addingTimeInterval(TimeInterval(totalDuration))

        activityController.start(title: blockTitle, endDate: endDate)

        engine = FocusTimerEngine(
            duration: totalDuration,
            onTick: { [weak self] remaining in
                Task { @MainActor in
                    self?.remainingSeconds = remaining
                }
            },
            onFinish: { [weak self] in
                Task { @MainActor in
                    self?.isRunning = false
                    self?.activityController.end()
                }
            }
        )

        Task {
            await engine?.start()
        }
    }

    public func pauseTimer() {
        isRunning = false
        Task {
            await engine?.pause()
            activityController.pause(currentRemainingDate: Date().addingTimeInterval(TimeInterval(remainingSeconds)))
        }
    }

    public func resetTimer() {
        isRunning = false
        remainingSeconds = durationMinutes * 60
        Task {
            await engine?.reset(to: remainingSeconds)
            activityController.end()
        }
    }

    public var timerFormatted: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    public var progress: Double {
        let total = Double(durationMinutes * 60)
        guard total > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / total)
    }
}

public struct FocusTimerView: View {
    @Bindable private var viewModel: FocusTimerViewModel

    public init(viewModel: FocusTimerViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            FocalColors.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 40) {
                VStack(spacing: 8) {
                    Text(viewModel.blockTitle)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(FocalColors.textPrimary)

                    Text("Stay present. Complete your block.")
                        .font(.system(size: 14))
                        .foregroundColor(FocalColors.textSecondary)
                }

                ZStack {
                    Circle()
                        .stroke(FocalColors.cardBackground, lineWidth: 16)

                    Circle()
                        .trim(from: 0, to: viewModel.progress)
                        .stroke(
                            FocalColors.primaryGradient,
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: viewModel.progress)

                    VStack(spacing: 8) {
                        Text(viewModel.timerFormatted)
                            .font(.system(size: 54, weight: .black, design: .rounded))
                            .foregroundColor(FocalColors.textPrimary)

                        Text(viewModel.isRunning ? "FOCUSING" : "PAUSED")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(viewModel.isRunning ? FocalColors.emeraldGreen : FocalColors.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(FocalColors.cardBackground)
                            .clipShape(Capsule())
                    }
                }
                .frame(width: 260, height: 260)
                .padding()

                HStack(spacing: 20) {
                    FocalButton(
                        title: viewModel.isRunning ? "Pause" : "Start",
                        icon: viewModel.isRunning ? "pause.fill" : "play.fill",
                        style: .primary
                    ) {
                        if viewModel.isRunning {
                            viewModel.pauseTimer()
                        } else {
                            viewModel.startTimer()
                        }
                    }

                    FocalButton(
                        title: "Reset",
                        icon: "arrow.counterclockwise",
                        style: .secondary
                    ) {
                        viewModel.resetTimer()
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding()
        }
    }
}
