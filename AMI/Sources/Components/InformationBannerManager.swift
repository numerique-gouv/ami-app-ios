import AmiDesignSystem
import Foundation
import Observation

@Observable
class InformationBannerManager {
    static let shared = InformationBannerManager()

    var banners: [InformationBannerModel] = []

    @discardableResult
    func showBanner(
        _ informationType: InformationBannerType,
        title: String,
        content: String? = nil,
        link: String? = nil,
        onClickLink: InformationBannerModel.LinkAction? = nil,
        icon: DsfrImageAsset? = nil,
        onClose: InformationBannerModel.CloseAction? = nil
    ) -> UUID {
        let bannerID = UUID()
        let bannerModel = InformationBannerModel(id: bannerID,
                                                 informationType: informationType,
                                                 title: title,
                                                 icon: icon,
                                                 content: content,
                                                 link: link,
                                                 onClickLink: onClickLink,
                                                 onClose: onClose != nil ? {
                                                     InformationBannerManager.shared.dismissBanner(id: bannerID)
                                                     onClose?()
                                                 } : nil) // No close button will be display in banner.
        banners.append(bannerModel)
        return bannerModel.id
    }

    func dismissBanner(id: UUID) {
        banners.removeAll { $0.id == id }
    }
}
