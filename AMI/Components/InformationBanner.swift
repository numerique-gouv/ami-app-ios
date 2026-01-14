import SwiftUI
import UIKit

enum InformationType {
    case warning
    case information
    case error
    case validation

    var backgroundColor: Color {
        switch self {
        case .warning:
            return Color.bannerWarningBackground
        case .information:
            return Color.bannerInformationBackground
        case .error:
            return Color.bannerErrorBackground
        case .validation:
            return Color.bannerValidationBackground
        }
    }

    var foregroundColor: Color {
        switch self {
        case .warning:
            return Color.bannerWarningForeground
        case .information:
            return Color.bannerInformationForeground
        case .error:
            return Color.bannerErrorForeground
        case .validation:
            return Color.bannerValidationForeground
        }
    }

    var borderColor: Color {
        switch self {
        case .warning:
            return Color.bannerWarningBorder
        case .information:
            return Color.bannerInformationBorder
        case .error:
            return Color.bannerErrorBorder
        case .validation:
            return Color.bannerValidationBorder
        }
    }
}

extension Color {
    // Warning colors (orange/amber)
    static let bannerWarningBackground = Color(light: Color(red: 1.0, green: 0.97, blue: 0.89),
                                                dark: Color(red: 0.3, green: 0.24, blue: 0.1))
    static let bannerWarningForeground = Color(light: Color(red: 0.6, green: 0.4, blue: 0.0),
                                                dark: Color(red: 1.0, green: 0.8, blue: 0.4))
    static let bannerWarningBorder = Color(light: Color(red: 0.9, green: 0.7, blue: 0.3),
                                            dark: Color(red: 0.7, green: 0.5, blue: 0.2))

    // Information colors (blue)
    static let bannerInformationBackground = Color(light: Color(red: 0.9, green: 0.95, blue: 1.0),
                                                    dark: Color(red: 0.1, green: 0.2, blue: 0.3))
    static let bannerInformationForeground = Color(light: Color(red: 0.0, green: 0.4, blue: 0.8),
                                                    dark: Color(red: 0.5, green: 0.75, blue: 1.0))
    static let bannerInformationBorder = Color(light: Color(red: 0.6, green: 0.8, blue: 1.0),
                                                dark: Color(red: 0.3, green: 0.5, blue: 0.7))

    // Error colors (red)
    static let bannerErrorBackground = Color(light: Color(red: 1.0, green: 0.92, blue: 0.92),
                                              dark: Color(red: 0.3, green: 0.1, blue: 0.1))
    static let bannerErrorForeground = Color(light: Color(red: 0.8, green: 0.2, blue: 0.2),
                                              dark: Color(red: 1.0, green: 0.5, blue: 0.5))
    static let bannerErrorBorder = Color(light: Color(red: 1.0, green: 0.6, blue: 0.6),
                                          dark: Color(red: 0.6, green: 0.3, blue: 0.3))

    // Validation/Success colors (green)
    static let bannerValidationBackground = Color(light: Color(red: 0.9, green: 1.0, blue: 0.92),
                                                   dark: Color(red: 0.1, green: 0.25, blue: 0.1))
    static let bannerValidationForeground = Color(light: Color(red: 0.2, green: 0.6, blue: 0.2),
                                                   dark: Color(red: 0.5, green: 0.9, blue: 0.5))
    static let bannerValidationBorder = Color(light: Color(red: 0.5, green: 0.8, blue: 0.5),
                                               dark: Color(red: 0.3, green: 0.5, blue: 0.3))
}

extension Color {
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}

struct InformationBanner: View {
    let informationType: InformationType
    let title: String
    let icon: String
    var content: String? = nil
    var link: String? = nil
    var hasCloseIcon: Bool = true
    var onClickLink: () -> Void = {}
    var onClose: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(informationType.foregroundColor)
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(informationType.foregroundColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if hasCloseIcon {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(informationType.foregroundColor)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .frame(alignment: .trailing)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                if let content = content {
                    Text(content)
                        .font(.system(size: 14))
                        .foregroundStyle(informationType.foregroundColor.opacity(0.9))
                }

                if let link = link {
                    Button(action: onClickLink) {
                        Text(link)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(informationType.foregroundColor)
                            .underline()
                    }
                    .padding(.top, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(informationType.backgroundColor)
        .overlay(
            Rectangle()
                .stroke(informationType.borderColor, lineWidth: 1)
        )
    }
}

#Preview("Warning") {
    InformationBanner(
        informationType: .warning,
        title: "Connexion indisponible",
        icon: "exclamationmark.triangle.fill",
        content: "Vérifiez votre connexion et réessayez.",
        link: "Lien de consultation",
        onClickLink: { print("Link clicked") },
        onClose: { print("Closed") }
    )
}

#Preview("Information") {
    InformationBanner(
        informationType: .information,
        title: "Nouvelle démarche disponible",
        icon: "info.square.fill",
        content: "Vérifiez votre connexion et réessayez.",
        link: "Lien de consultation",
        hasCloseIcon: false
    )
}

#Preview("Error") {
    InformationBanner(
        informationType: .error,
        title: "Application hors-service",
        icon: "xmark.circle.fill",
        content: "Vérifiez votre connexion et réessayez.",
        link: "Lien de consultation",
        onClickLink: { print("Retry clicked") },
        onClose: { print("Closed") }
    )
}

#Preview("Validation") {
    InformationBanner(
        informationType: .validation,
        title: "Connexion rétablie",
        icon: "checkmark.circle.fill",
        content: "L'application est de nouveau fonctionnelle.",
        link: "Lien de consultation",
    )
}

#Preview("All Types") {
    VStack(spacing: 16) {
        InformationBanner(
            informationType: .warning,
            title: "Connexion indisponible",
            icon: "exclamationmark.triangle.fill",
            content: "Vérifiez votre connexion et réessayez.",
            link: "Lien de consultation",
            onClickLink: { print("Link clicked") },
            onClose: { print("Closed") }
        )
        InformationBanner(
            informationType: .information,
            title: "Nouvelle démarche disponible",
            icon: "info.square.fill",
            content: "Vérifiez votre connexion et réessayez.",
            link: "Lien de consultation",
            hasCloseIcon: false
        )
        InformationBanner(
            informationType: .error,
            title: "Application hors-service",
            icon: "xmark.circle.fill",
            content: "Vérifiez votre connexion et réessayez.",
            link: "Lien de consultation",
            onClickLink: { print("Retry clicked") },
            onClose: { print("Closed") }
        )
        InformationBanner(
            informationType: .validation,
            title: "Connexion rétablie",
            icon: "checkmark.circle.fill",
            content: "L'application est de nouveau fonctionnelle.",
            link: "Lien de consultation",
        )
    }
}

#Preview("Dark Mode") {
    VStack(spacing: 16) {
        InformationBanner(
            informationType: .warning,
            title: "Connexion indisponible",
            icon: "exclamationmark.triangle.fill",
            content: "Vérifiez votre connexion et réessayez.",
            link: "Lien de consultation",
            onClickLink: { print("Link clicked") },
            onClose: { print("Closed") }
        )
        InformationBanner(
            informationType: .information,
            title: "Nouvelle démarche disponible",
            icon: "info.square.fill",
            content: "Vérifiez votre connexion et réessayez.",
            link: "Lien de consultation",
            hasCloseIcon: false
        )
        InformationBanner(
            informationType: .error,
            title: "Application hors-service",
            icon: "xmark.circle.fill",
            content: "Vérifiez votre connexion et réessayez.",
            link: "Lien de consultation",
            onClickLink: { print("Retry clicked") },
            onClose: { print("Closed") }
        )
        InformationBanner(
            informationType: .validation,
            title: "Connexion rétablie",
            icon: "checkmark.circle.fill",
            content: "L'application est de nouveau fonctionnelle.",
            link: "Lien de consultation",
        )
    }
    .preferredColorScheme(.dark)
}
