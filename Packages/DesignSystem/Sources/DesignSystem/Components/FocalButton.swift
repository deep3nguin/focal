import SwiftUI

public struct FocalButton: View {
    public enum Style {
        case primary
        case secondary
        case destructive
    }

    private let title: String
    private let icon: String?
    private let style: Style
    private let action: () -> Void

    public init(
        title: String,
        icon: String? = nil,
        style: Style = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(buttonBackground)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PressedScaleButtonStyle())
    }

    @ViewBuilder
    private var buttonBackground: some View {
        switch style {
        case .primary:
            FocalColors.primaryGradient
        case .secondary:
            FocalColors.cardBackground
        case .destructive:
            Color.red.opacity(0.85)
        }
    }

    private var shadowColor: Color {
        switch style {
        case .primary:
            return FocalColors.primaryAccent.opacity(0.4)
        case .secondary:
            return Color.black.opacity(0.2)
        case .destructive:
            return Color.red.opacity(0.3)
        }
    }
}

public struct PressedScaleButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
