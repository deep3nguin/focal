import SwiftUI
import Domain
import DesignSystem

@MainActor
@Observable
public final class BrainDumpViewModel {
    public var rawText: String = ""
    public var isParsing: Bool = false
    public var suggestions: [ParsedTaskSuggestion] = []
    public var errorMessage: String? = nil

    private let aiService: AIServiceProtocol?

    public init(aiService: AIServiceProtocol? = nil) {
        self.aiService = aiService
    }

    public func parseBrainDump() async {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard let aiService else {
            // Fallback when no AI service configured
            suggestions = [ParsedTaskSuggestion(title: trimmed)]
            return
        }

        isParsing = true
        errorMessage = nil

        do {
            suggestions = try await aiService.parseBrainDump(trimmed)
        } catch let err as AIServiceError {
            switch err {
            case .missingAPIKey:
                errorMessage = "API key missing. Please configure your API key in Settings."
            case .rateLimited:
                errorMessage = "Rate limit reached. Please wait a moment before trying again."
            case .invalidResponse, .network, .decoding:
                errorMessage = "Could not parse tasks automatically. Raw text converted to task."
            }
            suggestions = [ParsedTaskSuggestion(title: trimmed)]
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
            suggestions = [ParsedTaskSuggestion(title: trimmed)]
        }

        isParsing = false
    }

    public func removeSuggestion(id: UUID) {
        suggestions.removeAll(where: { $0.id == id })
    }
}

public struct BrainDumpView: View {
    @Bindable private var viewModel: BrainDumpViewModel

    public init(viewModel: BrainDumpViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            FocalColors.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Brain Dump")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(FocalColors.textPrimary)

                        Text("Unload your mind into actionable tasks.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(FocalColors.textSecondary)
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            TextEditor(text: $viewModel.rawText)
                                .frame(height: 120)
                                .scrollContentBackground(.hidden)
                                .foregroundColor(FocalColors.textPrimary)
                                .font(.system(size: 16))

                            HStack {
                                Spacer()
                                FocalButton(
                                    title: viewModel.isParsing ? "Parsing..." : "Parse with AI",
                                    icon: "sparkles",
                                    style: .primary
                                ) {
                                    Task {
                                        await viewModel.parseBrainDump()
                                    }
                                }
                                .disabled(viewModel.isParsing || viewModel.rawText.isEmpty)
                            }
                        }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(FocalColors.amberWarning)
                            Text(errorMessage)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(FocalColors.textPrimary)
                        }
                        .padding()
                        .background(FocalColors.cardBackground)
                        .cornerRadius(12)
                    }

                    if !viewModel.suggestions.isEmpty {
                        Text("Suggested Tasks (\(viewModel.suggestions.count))")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(FocalColors.textPrimary)

                        ForEach(viewModel.suggestions) { suggestion in
                            GlassCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(suggestion.title)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(FocalColors.textPrimary)

                                        if let est = suggestion.estimatedMinutes {
                                            Text("Est. \(est) mins")
                                                .font(.system(size: 12))
                                                .foregroundColor(FocalColors.primaryAccent)
                                        }
                                    }

                                    Spacer()

                                    Button {
                                        viewModel.removeSuggestion(id: suggestion.id)
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(FocalColors.emeraldGreen)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}
