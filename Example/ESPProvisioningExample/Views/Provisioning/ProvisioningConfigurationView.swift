import SwiftUI
import ESPProvision


import CoreLocation

struct ProvisioningConfigurationView: View {

    enum Transport: Int {
        case ble
        case softAP
    }

    @AppStorage("settingSecurityMode") var securityMode: Int = 0
    @AppStorage("settingTransport") var transport: Transport = .ble
    @AppStorage("settingBleNamePrefix") var bleNamePrefix: String = "PROV_"
    @AppStorage("settingPopOrPassword") var popOrPassword: String = ""
    @AppStorage("settingUsername") var username: String = ""

    @State var provisioningPresented: Bool = false

    var body: some View {
        Form {
            Section {
                Picker("Transport", selection: $transport) {
                    Text("BLE")
                        .tag(Transport.ble)
                    Text("SoftAP")
                        .tag(Transport.softAP)
                }
            }

            if transport == .ble {
                bleConfiguration()
            } else {
                Text("Not yet implemented")
            }
        }
        .sheet(isPresented: $provisioningPresented,
               onDismiss: {},
               content: {
            if transport == .softAP {
                Text("Not yet implemented")
            } else {
                let viewModel = ManualBLEProvisioningViewModel(securityMode: securityMode, prefix: bleNamePrefix, popOrPassword: popOrPassword, username: username)
                BLEDevicesListView(viewModel: viewModel, presented: $provisioningPresented)
            }
        })
        .navigationTitle("Settings")
    }

    @ViewBuilder
    private func bleConfiguration() -> some View {
        Section {
            Picker("Security mode", selection: $securityMode) {
                Text("Mode 0")
                    .tag(0)
                Text("Mode 1")
                    .tag(1)
                Text("Mode 2")
                    .tag(2)
            }

            TextField("Prefix", text: $bleNamePrefix)
                .autocorrectionDisabled()
        } header: {
            Text("Connection setup")
        } footer: {
            VStack(alignment: .leading, spacing: 5) {
                Text("Configure the provisioning library to match your device's provisioning configuration. Security modes are:")
                VStack(alignment: .leading) {
                    Text("Mode 0 - no cretentials")
                    Text("Mode 1 - POP (proof of posession)")
                    Text("Mode 2 - username / password")
                }
                .font(.system(size: 13, design: .monospaced))
            }
        }

        if securityMode != 0 {
            Section {
                TextField(securityMode == 1 ? "POP" : "Password", text: $popOrPassword)
                    .autocorrectionDisabled()
                if securityMode == 2 {
                    TextField("Username", text: $username)
                        .autocorrectionDisabled()
                }
            } header: {
                Text("Credentials")
            }
        }

        Section {
            Button {
                provisioningPresented = true
            } label: {
                Text("Find devices")
            }
            .frame(maxWidth: .infinity)
        }
    }
}
