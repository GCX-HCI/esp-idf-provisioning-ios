import SwiftUI
import ESPProvision
import Combine

struct ConnectAndShowWifiListView: View {
    @State var selectedWifi: ESPWifiNetwork?
    @AppStorage("wifiPassphrase") var wifiPassphrase: String = ""
    @ObservedObject var viewModel: ProvisioningViewModel

    @Binding var presented: Bool

    var body: some View {
        VStack {
            if let wifiList = viewModel.wifiList {
                Form {
                    Section {
                        ForEach(wifiList, id: \.self) { network in
                            wifiEntry(network: network)
                        }
                    } header: {
                        Text("Select your WiFi network")
                    }

                    if let selectedWifi = selectedWifi, selectedWifi.auth != .open {
                        Section {
                            TextField("Passphrase", text: $wifiPassphrase)
                                .autocorrectionDisabled()
                        } header: {
                            Text("Passphrase")
                        }
                    }

                    Section {
                        Button("Provision") {
                            if let ssid = selectedWifi?.ssid {
                                viewModel.provision(ssid: ssid, passphrase: wifiPassphrase)
                            }
                        }
                        .disabled(selectedWifi == nil || (selectedWifi?.auth != .open && (selectedWifi?.auth != .open && wifiPassphrase.isEmpty)))
                        .frame(maxWidth: .infinity)

                        Button("Scan") {
                            viewModel.scanWifiNetworks()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            } else if viewModel.state == .idle  {
                Text("No networks")
            }
        }
        .onDisappear() {
            viewModel.closeSession()
        }
        .isBlocked(
            [.connecting, .scanningWifi, .provisioning].contains(viewModel.state),
            message: viewModel.state.message
        )
    }

    @ViewBuilder
    private func wifiEntry(network: ESPWifiNetwork) -> some View {
        Button {
            selectedWifi = network
        } label: {
            HStack {
                Group {
                    if selectedWifi == network {
                        Image(systemName: "checkmark.circle.fill")
                    } else {
                        Image(systemName: "circle.dashed")
                            .opacity(0.25)
                    }
                }
                .frame(width: 40)

                Text(network.ssid)

                Spacer()

                HStack {
                    SignalStrengthView(rssi: Int(network.rssi))
                    Image(systemName: network.auth != .open ? "lock.fill" : "lock.open")
                        .frame(width: 30)
                }
            }
        }
    }
}

extension ESPWifiNetwork: Hashable {
    public static func == (lhs: ESPWifiNetwork, rhs: ESPWifiNetwork) -> Bool {
        lhs.bssid == rhs.bssid
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.bssid)
    }
}
