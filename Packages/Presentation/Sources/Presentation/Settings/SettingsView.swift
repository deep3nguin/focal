import SwiftUI
import Domain
import DesignSystem

@MainActor
@Observable
public final class SettingsViewModel {
    public var selectedProvider: AIProvider = .gemini
    public var geminiAPIKey: String = ""
    public var openAIAPIKey: String = ""
    public var statusMessage: String? = nil

    private let keyStore: APIKeyStoring?

    public init(keyStore: APIKeyStoring? = nil) {
        self.keyStore = keyStore
        loadKeys()
    }

    public func loadKeys() {
        guard let keyStore else { return }
        do {
            geminiAPIKey = (try keyStore.retrieve(for: .gemini)) ?? ""
            openAIAPIKey = (try keyStore.retrieve(for: .openAI)) ?? ""
        } catch {
            statusMessage = "Could not load saved keys from Keychain."
        }
    }

    public func saveKeys() {
        guard let keyStore else {
            statusMessage = "Key store not initialized."
            return
        }

        do {
            if !geminiAPIKey.isEmpty {
                try keyStore.save(geminiAPIKey, for: .gemini)
            } else {
                try keyStore.delete(for: .gemini)
            }

            if !openAIAPIKey.isEmpty {
                try keyStore.save(openAIAPIKey, for: .openAI)
            } else {
                try keyStore.delete(for: .openAI)
            }

            statusMessage = "API Keys saved securely in Keychain."
        } catch {
            statusMessage = "Error saving keys: \(error.localizedDescription)"
        }
    }
}

public struct SettingsView: View {
    @Bindable private var viewModel: SettingsViewModel

    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            FocalColors.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Settings")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(FocalColors.textPrimary)

                        Text("Configure your BYOK AI providers and options.")
                            .font(.system(size: 14))
                            .foregroundColor(FocalColors.textSecondary)
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Active AI Provider")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(FocalColors.textPrimary)

                            Picker("Provider", selection: $viewModel.selectedProvider) {
                                ForEach(AIProvider.allCases) { provider in
                                    Text(provider.displayName).tag(provider)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("API Keys (Stored in iOS Keychain)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(FocalColors.textPrimary)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Google Gemini API Key")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(FocalColors.textSecondary)

                                SecureField("AIzaSy...", text: $viewModel.geminiAPIKey)
                                    .textFieldStyle(.plain)
                                    .padding(12)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(10)
                                    .foregroundColor(FocalColors.textPrimary)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("OpenAI API Key")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(FocalColors.textSecondary)

                                SecureField("sk-...", text: $viewModel.openAIAPIKey)
                                    .textFieldStyle(.plain)
                                    .padding(12)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(10)
                                    .foregroundColor(FocalColors.textPrimary)
                            }

                            FocalButton(title: "Save Keys", icon: "lock.shield.fill", style: .primary) {
                                viewModel.saveKeys()
                            }
                        }
                    }

                    if let status = viewModel.statusMessage {
                        Text(status)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(FocalColors.emeraldGreen)
                            .padding(.horizontal)
                    }
                }
                .padding()
            }
        }
    }
}
