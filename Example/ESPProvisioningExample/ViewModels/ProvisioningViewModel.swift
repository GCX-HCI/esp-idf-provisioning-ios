import SwiftUI
import ESPProvision

class ProvisioningViewModel: ObservableObject {
    enum Mode {
        case manual
        case qrCode
    }

    enum State {
        case idle
        case connecting
        case scanningQRCode
        case scanningDevices
        case scanningWifi
        case provisioning
    }

    @Published var state: State = .idle

    @Published var connected = false
    @Published var provisioned = false

    @Published var message: Message?

    @Published var wifiList: [ESPProvision.ESPWifiNetwork]? = nil

    var mode: Mode
    private(set) var device: ESPDevice? = nil

    init(_ mode: Mode) {
        self.mode = mode
    }

    func setDevice(device: ESPDevice) {
        if device.isSessionEstablished() {
            device.disconnect()
        }

        self.device = device
        connected = false
    }

    func closeSession() {
        device?.disconnect()
        wifiList = nil
        connected = false
        provisioned = false
    }

    @MainActor
    func connect() {
        Task {
            do {
                try await connect()
            } catch {
                handleErrors(error)
            }
        }
    }

    @MainActor
    private func connect() async throws {
        guard let device = device else {
            throw ESPDeviceCSSError.espDeviceNotFound
        }

        defer {
            state = .idle
        }

        let asyncConnect = createAsyncConnect(device: device)

        state = .connecting
        try await asyncConnect.connect()
        connected = true

        try await scanWifiNetworks()
    }

    @MainActor
    func scanWifiNetworks() {
        Task {
            do {
                try await scanWifiNetworks()
            } catch {
                handleErrors(error)
            }
        }
    }

    @MainActor
    private func scanWifiNetworks() async throws {
        defer {
            state = .idle
        }

        guard let device = device else {
            throw ESPDeviceCSSError.espDeviceNotFound
        }

        if device.isSessionEstablished() {
            state = .scanningWifi
            wifiList = try await device.scanWifiList()
        } else {
            throw ESPSessionError.sessionNotEstablished
        }
    }

    @MainActor
    func provision(ssid: String, passphrase: String) {
        Task {
            do {
                try await provision(ssid: ssid, passphrase: passphrase)
            } catch {
                handleErrors(error)
            }
        }
    }

    @MainActor
    private func provision(ssid: String, passphrase: String) async throws {
        guard let device = device else {
            throw ESPDeviceCSSError.espDeviceNotFound
        }

        defer {
            state = .idle
        }

        state = .provisioning
        try await device.provision(ssid: ssid, password: passphrase)
        provisioned = true
        message = .success("The device was provisioned successfully!")
    }

    func createAsyncConnect(device: ESPDevice) -> ESPDeviceAsyncConnect {
        return ESPDeviceAsyncConnect(device: device) { [weak self] error in
            self?.handleErrors(error)
        }
    }

    func handleErrors(_ error: Error?){
        // if error = nil -> disconnected by lib / user
        // bleFailedToConnect - disconnect during connection attempt to device
        // sessionInitError - wrong pop
        // ESPProvision.ESPDeviceCSSError - no devices found
        DispatchQueue.main.async { [weak self] in
            if let localizedError = (error as? LocalizedError) {
                self?.message = .error(localizedError)
            } else {
                if let error = error {
                    self?.message = .error(GenericError.some(error))
                }
            }

            if let _ = (error as? ESPSessionError){
                self?.closeSession()
            }
        }
    }
}


class QRCodeProvisioningViewModel: ProvisioningViewModel {
    @Published var cameraAccessPermitted = true

    var previewView: UIView?

    init() {
        super.init(.qrCode)
    }

    @MainActor
    public func scanQRCode(previewView: UIView) {
        Task {
            do {
                try await scanQRCode(previewView: previewView) { [weak self] status in
                    switch status {
                    case .readingCode:
                        self?.state = .scanningQRCode
                    default:
                        break
                    }
                }
            } catch {
                handleErrors(error)
            }
        }
    }

    @MainActor
    private func scanQRCode(previewView: UIView, scanStatusCallback: @escaping (ESPScanStatus) -> Void) async throws {
        defer {
            state = .idle
        }

        self.previewView = previewView

        let device = try await ESPProvisionManager.shared.scanQRCode(scanView: previewView, scanStatusCallback: scanStatusCallback)

        self.setDevice(device: device)

        switch device.transport {
        case .ble:
            self.connect()
        case .softap:
            // taken from original code, don't know why it's needed
            try await Task.sleep(nanoseconds: 1_000_000)
            self.connect()
        }
    }

    override func handleErrors(_ error: Error?) {
        if let error = (error as? ESPProvision.ESPDeviceCSSError) {
            switch error {
            case .cameraAccessDenied:
                self.cameraAccessPermitted = false
            case .espDeviceNotFound:
                self.message = .error(error)
            default:
                break
            }
        }

        super.handleErrors(error)
    }
}

class ManualBLEProvisioningViewModel: ProvisioningViewModel {

    @Published var devices = [ESPDevice]()

    var prefix: String
    var popOrPassword: String?
    var username: String?

    init(securityMode: Int, prefix: String, popOrPassword: String?, username: String?) {
        self.prefix = prefix
        self.popOrPassword = popOrPassword
        self.username = username
        super.init(.manual)
    }

    @MainActor
    func scanForDevices() {
        Task {
            defer {
                state = .idle
            }

            do {
                state = .scanningDevices
                try await scanForDevices()
            } catch {
                devices = []
                handleErrors(error)
            }
        }
    }

    private func scanForDevices() async throws {
        devices = try await ESPProvisionManager.shared.searchESPDevices(prefix: prefix)
    }

    override func createAsyncConnect(device: ESPDevice) -> ESPDeviceAsyncConnect {
        return ESPDeviceAsyncConnect(device: device, pop: popOrPassword, username: username) { [weak self] error in
            self?.handleErrors(error)
        }
    }
}

extension ProvisioningViewModel.State {
    var message: String {
        switch self {
        case .idle:
            return ""
        case .connecting:
            return "Connecting"
        case .scanningQRCode:
            return "Processing QR code"
        case .scanningDevices:
            return "Discovering devices"
        case .scanningWifi:
            return "Discovering WiFi networks"
        case .provisioning:
            return "Provisioning"
        }
    }
}
