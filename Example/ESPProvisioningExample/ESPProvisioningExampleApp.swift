import SwiftUI
import ESPProvision

@main
struct ESPProvisioningExampleApp: App {

    @State var qrCodeScanViewPresented: Bool = false

    init() {
        ESPProvisionManager.shared.enableLogs(false)
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                List {
                    NavigationLink {
                        ProvisioningPermissionsView()
                    } label: {
                        Text("Manual provisioning")
                    }

                    NavigationLink(isActive: $qrCodeScanViewPresented) {
                        QRCodeScanView(presented: $qrCodeScanViewPresented)
                    } label: {
                        Text("Provisioning using QR code")
                    }
                }
            }
        }
    }
}
