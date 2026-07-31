import SwiftUI

public enum FocalColors {
    public static let backgroundDark = Color(red: 0.07, green: 0.08, blue: 0.12)
    public static let cardBackground = Color(red: 0.12, green: 0.14, blue: 0.20).opacity(0.85)
    public static let glassBorder = Color.white.opacity(0.12)
    public static let primaryAccent = Color(red: 0.39, green: 0.40, blue: 0.95) // Indigo/Violet
    public static let secondaryAccent = Color(red: 0.93, green: 0.34, blue: 0.60) // Pink/Coral
    public static let emeraldGreen = Color(red: 0.16, green: 0.80, blue: 0.60)
    public static let amberWarning = Color(red: 0.98, green: 0.70, blue: 0.24)
    public static let textPrimary = Color.white
    public static let textSecondary = Color.white.opacity(0.65)

    public static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.06, blue: 0.10),
            Color(red: 0.09, green: 0.10, blue: 0.18),
            Color(red: 0.04, green: 0.05, blue: 0.09)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let primaryGradient = LinearGradient(
        colors: [primaryAccent, secondaryAccent],
        startPoint: .leading,
        endPoint: .trailing
    )
}
