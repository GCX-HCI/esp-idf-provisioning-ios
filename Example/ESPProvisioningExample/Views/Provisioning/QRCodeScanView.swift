import SwiftUI
import ESPProvision

struct QRCodeScanView: View {
    @Environment(\.presentationMode) var presentation
    @StateObject var viewModel = QRCodeProvisioningViewModel()

    @Binding var presented: Bool

    func dealloc() {
        viewModel.closeSession()
    }

    var body: some View {
        Group {
            if viewModel.cameraAccessPermitted {
                if !viewModel.connected {
                    QRCodeScanPreviewView(viewModel: viewModel)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ConnectAndShowWifiListView(viewModel: viewModel, presented: .constant(true))
                }
            } else {
                GoToSettingsVew(image: Image(systemName: "video.slash"), message: "Missing permissions! Please enable camera access for the app in the settings screen")
                    .padding(50)
            }
        }
        .isBlocked(
            [.scanningQRCode, .connecting, .scanningWifi].contains(viewModel.state),
            message: viewModel.state.message    
        )
        .messageAlert($viewModel.message) { message in
            switch message {
            case .error(let error):
                if (error is ESPSessionError || error is ESPDeviceCSSError) {
                    // dismiss on session errors
                    presented = false
                }
            case .success(_):
                // dismiss on success message
                presented = false
            }
        }
    }
}

struct QRCodeScanPreviewView: UIViewControllerRepresentable {
    let viewModel: QRCodeProvisioningViewModel

    func makeUIViewController(context: Context) -> some UIViewController {
        let viewController = UIViewController()
        viewModel.scanQRCode(previewView: viewController.view)

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }
}
