import SwiftUI
import FirebaseCore
import SwiftData
import Cloudinary

@main
struct SologramApp: App {
    init() {
        FirebaseApp.configure()
        setupCloudinary()
    }

    func setupCloudinary() {
        let cloudinaryConfig = CLDConfiguration(
            cloudName: "dl1ajqx6c",
            apiKey: "362329481363912",
            apiSecret: "9SmqkB_CY_wOJxaKpcRtZs7EbGw"
        )
    }

    var body: some Scene {
        WindowGroup {
            NavigationView {
                LoginView(userImages: .constant([]))
            }
        }
    }
}
