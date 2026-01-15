import SwiftUI
import UIKit

struct BannerData: Identifiable {
    let id: UUID
    let informationType: InformationType
    let title: String
    let icon: String
    let content: String?
    let link: String?
    let hasCloseIcon: Bool
    let onClickLink: () -> Void
    let onClose: (() -> Void)?
}

class InformationBannerManager: ObservableObject {
    static let shared = InformationBannerManager()

    @Published var banners: [BannerData] = []

    @discardableResult
    func showBanner(
        _ informationType: InformationType,
        title: String,
        content: String? = nil,
        link: String? = nil,
        onClickLink: @escaping () -> Void = {},
        hasCloseIcon: Bool = true,
        icon: String? = nil,
        onClose: (() -> Void)? = nil
    ) -> UUID {
        let id = UUID()
        let banner = BannerData(
            id: id,
            informationType: informationType,
            title: title,
            icon: icon ?? informationType.defaultIcon,
            content: content,
            link: link,
            hasCloseIcon: hasCloseIcon,
            onClickLink: onClickLink,
            onClose: onClose
        )
        banners.append(banner)
        return id
    }

    func dismissBanner(id: UUID) {
        banners.removeAll { $0.id == id }
    }
}

enum InformationType {
    case warning
    case information
    case error
    case validation

    var defaultIcon: String {
        switch self {
        case .warning:
            return "exclamationmark.triangle.fill"
        case .information:
            return "info.square.fill"
        case .error:
            return "xmark.circle.fill"
        case .validation:
            return "checkmark.circle.fill"
        }
    }

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
}

extension Color {
    // Warning colors (orange/amber)
    static let bannerWarningBackground = Color(light: Color(red: 0.996, green: 0.922, blue: 0.816),
                                                dark: Color(red: 0.702, green: 0.251, blue: 0))
    static let bannerWarningForeground = Color(light: Color(red: 0.702, green: 0.251, blue: 0),
                                                dark: Color(red: 0.996, green: 0.922, blue: 0.816))
    // Information colors (blue)
    static let bannerInformationBackground = Color(light: Color(red: 0.91, green: 0.929, blue: 1),
                                                    dark: Color(red: 0, green: 0.388, blue: 0.796))
    static let bannerInformationForeground = Color(light: Color(red: 0, green: 0.388, blue: 0.796),
                                                    dark: Color(red: 0.91, green: 0.929, blue: 1))

    // Error colors (red)
    static let bannerErrorBackground = Color(light: Color(red: 1, green: 0.914, blue: 0.914),
                                              dark: Color(red: 0.808, green: 0.02, blue: 0))
    static let bannerErrorForeground = Color(light: Color(red: 0.808, green: 0.02, blue: 0),
                                              dark: Color(red: 1, green: 0.914, blue: 0.914))

    // Validation/Success colors (green)
    static let bannerValidationBackground = Color(light: Color(red: 0.89, green: 0.992, blue: 0.922),
                                                   dark: Color(red: 0.094, green: 0.459, blue: 0.235))
    static let bannerValidationForeground = Color(light: Color(red: 0.094, green: 0.459, blue: 0.235),
                                                   dark: Color(red: 0.89, green: 0.992, blue: 0.922))
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

    init(data: BannerData) {
        self.informationType = data.informationType
        self.title = data.title
        self.icon = data.icon
        self.content = data.content
        self.link = data.link
        self.hasCloseIcon = data.hasCloseIcon
        self.onClickLink = data.onClickLink
        self.onClose = {
            data.onClose?()
            InformationBannerManager.shared.dismissBanner(id: data.id)
        }
    }

    init(
        informationType: InformationType,
        title: String,
        icon: String,
        content: String? = nil,
        link: String? = nil,
        hasCloseIcon: Bool = true,
        onClickLink: @escaping () -> Void = {},
        onClose: @escaping () -> Void = {}
    ) {
        self.informationType = informationType
        self.title = title
        self.icon = icon
        self.content = content
        self.link = link
        self.hasCloseIcon = hasCloseIcon
        self.onClickLink = onClickLink
        self.onClose = onClose
    }

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
