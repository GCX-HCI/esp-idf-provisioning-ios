import SwiftUI
import ESPProvision

extension ESPDevice: Hashable {
    public static func == (lhs: ESPProvision.ESPDevice, rhs: ESPProvision.ESPDevice) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
        hasher.combine(self.security)
        hasher.combine(self.capabilities)
        hasher.combine(self.transport)
        hasher.combine(self.versionInfo)
    }
}

struct BLEDevicesListView: View {
    @ObservedObject var viewModel: ManualBLEProvisioningViewModel
    @State private var selectedDevice: ESPDevice? = nil
    @Binding var presented: Bool

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    Form {
                        Section {
                            ForEach(viewModel.devices, id:\.name) { device in
                                let view = ConnectAndShowWifiListView(viewModel: viewModel, presented: $presented)
                                    .onAppear {
                                        if let selectedDevice = selectedDevice {
                                            viewModel.setDevice(device: selectedDevice)
                                            viewModel.connect()
                                        }
                                    }
                                NavigationLink(
                                    destination: view, tag: device, selection: $selectedDevice) { Text(device.name) }
                            }
                        }

                        Section {
                            Button("Rescan") {
                                viewModel.scanForDevices()
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .isBlocked(viewModel.state == .scanningDevices, message: viewModel.state.message)
            }
            .onAppear() {
                viewModel.scanForDevices()
            }
            .navigationTitle("Select device")
        }
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
