import SwiftUI
import Domain
import DesignSystem

@MainActor
@Observable
public final class TimelineViewModel {
    public struct VisualBlock: Identifiable, Sendable {
        public let id: UUID
        public var title: String
        public var timeRange: String
        public var isCompleted: Bool
        public var icon: String
        public var colorHex: String

        public init(
            id: UUID = UUID(),
            title: String,
            timeRange: String,
            isCompleted: Bool = false,
            icon: String = "clock.fill",
            colorHex: String = "#6366F1"
        ) {
            self.id = id
            self.title = title
            self.timeRange = timeRange
            self.isCompleted = isCompleted
            self.icon = icon
            self.colorHex = colorHex
        }
    }

    public var selectedDate: Date = Date()
    public var blocks: [VisualBlock] = []

    public init() {
        loadSampleData()
    }

    public func loadSampleData() {
        blocks = [
            VisualBlock(title: "Deep Work - Focal Dev", timeRange: "09:00 - 11:00", isCompleted: false, icon: "laptopcomputer", colorHex: "#6366F1"),
            VisualBlock(title: "Team Sync & Planning", timeRange: "11:30 - 12:00", isCompleted: true, icon: "person.2.fill", colorHex: "#EC4899"),
            VisualBlock(title: "Lunch & Walk", timeRange: "12:30 - 13:30", isCompleted: true, icon: "figure.walk", colorHex: "#10B981"),
            VisualBlock(title: "Code Review & Shipping", timeRange: "14:00 - 16:30", isCompleted: false, icon: "hammer.fill", colorHex: "#F59E0B")
        ]
    }

    public func toggleCompletion(for blockID: UUID) {
        if let index = blocks.firstIndex(where: { $0.id == blockID }) {
            blocks[index].isCompleted.toggle()
        }
    }
}

public struct TimelineView: View {
    @Bindable private var viewModel: TimelineViewModel

    public init(viewModel: TimelineViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            FocalColors.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerView

                    Text("Today's Schedule")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(FocalColors.textPrimary)
                        .padding(.horizontal)

                    LazyVStack(spacing: 14) {
                        ForEach(viewModel.blocks) { block in
                            blockRow(block)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.selectedDate.formatted(date: .complete, time: .omitted))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(FocalColors.textSecondary)

                Text("Focal Timeline")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(FocalColors.textPrimary)
            }

            Spacer()

            Image(systemName: "calendar")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(FocalColors.primaryAccent)
                .padding(12)
                .background(FocalColors.cardBackground)
                .clipShape(Circle())
        }
        .padding(.horizontal)
    }

    private func blockRow(_ block: TimelineViewModel.VisualBlock) -> some View {
        GlassCard {
            HStack(spacing: 16) {
                Button {
                    viewModel.toggleCompletion(for: block.id)
                } label: {
                    Image(systemName: block.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(block.isCompleted ? FocalColors.emeraldGreen : FocalColors.textSecondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(block.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(block.isCompleted ? FocalColors.textSecondary : FocalColors.textPrimary)
                        .strikethrough(block.isCompleted, color: FocalColors.textSecondary)

                    Text(block.timeRange)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(FocalColors.textSecondary)
                }

                Spacer()

                Image(systemName: block.icon)
                    .font(.system(size: 18))
                    .foregroundColor(FocalColors.primaryAccent)
            }
        }
    }
}
