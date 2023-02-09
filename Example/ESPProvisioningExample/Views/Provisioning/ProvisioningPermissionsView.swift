import SwiftUI
import CoreBluetooth

struct ProvisioningPermissionsView: View {
    @ObservedObject private var viewModel = ViewModel()

    var body: some View {
        ZStack {
            if viewModel.state == .poweredOn || viewModel.state == .unauthorized {
                switch viewModel.authorization {
                case .notDetermined:
                    Button {
                        viewModel.triggerBluetoothPermissionsDialog()
                    } label: {
                        Text("Determine permission")
                            .font(.title)
                    }
                case .restricted:
                    Text("Restricted")
                case .allowedAlways:
                    ProvisioningConfigurationView()
                case .denied:
                    GoToSettingsVew(image: Image(systemName: "wifi.slash"), message: "Missing permissions! Please enable Bluetooth access for the app in the settings screen")
                        .padding(50)
                @unknown default:
                    fatalError()
                }
            } else {
                VStack(spacing: 20) {
                    Button {
                        viewModel.triggerBluetoothPermissionsDialog()
                    } label: {
                        Text("Enable")
                    }
                    Text("Bluetooth disabled. Please enable Bluetooth on your device")
                        .font(.footnote)
                }
                .padding()
            }
        }
        .onAppear() {
            viewModel.triggerBluetoothPermissionsDialog()
        }
    }
}

extension ProvisioningPermissionsView {
    private class CentralManagerDelegate: NSObject, CBCentralManagerDelegate {
        var onStateChange: ((CBManagerState) -> Void)?

        func centralManagerDidUpdateState(_ central: CBCentralManager) {
            onStateChange?(central.state)
        }
    }

    class ViewModel: ObservableObject {
        @Published var authorization: CBManagerAuthorization = .notDetermined
        @Published var state: CBManagerState = .unknown

        private var centralManagerDelegate: CentralManagerDelegate?
        private var centralManager: CBCentralManager?

        private var peripheralManagerDelegate: CBPeripheralManagerDelegate?
        private var peripheralManager: CBPeripheralManager?

        func updateAuthorization() {
            authorization = CBManager.authorization
        }

        @MainActor
        func triggerBluetoothPermissionsDialog() {
            centralManagerDelegate = CentralManagerDelegate()
            centralManagerDelegate?.onStateChange = { [weak self] state in
                self?.updateAuthorization()
                self?.state = state
            }

            centralManager = CBCentralManager(delegate: centralManagerDelegate, queue: nil)
        }
    }
}
