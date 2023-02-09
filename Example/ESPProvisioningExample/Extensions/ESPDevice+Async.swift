import Foundation
import ESPProvision
import CoreBluetooth
import SwiftProtobuf

class ESPDeviceAsyncConnect: ESPBLEDelegate, ESPDeviceConnectionDelegate {

    private var ESPDeviceDelegate: ESPBLEDelegate?

    private let device: ESPDevice
    private let deviceDisconnectedCallback: (Error?) -> Void
    private var continuation: CheckedContinuation<Void, Error>?
    private let pop: String?
    private let username: String?

    deinit {
        print(#function)
    }

    init(device: ESPDevice, pop: String? = nil, username: String? = nil, deviceDisconnectedCallback: @escaping (Error?) -> Void) {
        self.deviceDisconnectedCallback = deviceDisconnectedCallback
        self.device = device
        self.pop = pop
        self.username = username
        device.bleDelegate = self
    }

    func connect() async throws -> Void {
        try await withCheckedThrowingContinuation({ continuation in
            self.continuation = continuation
            DispatchQueue.global().async { [weak self] in
                self?.device.connect(delegate: self) { status in
                    switch status {
                    case .connected:
                        self?.continuation?.resume()
                    case .failedToConnect(let eSPSessionError):
                        self?.continuation?.resume(throwing: eSPSessionError)
                    case .disconnected:
                        // can never happen, it's the initial state of ESPDevice
                        break
                    }
                    self?.continuation = nil
                }
            }            
        })
    }

    // MARK: ESPBLEDelegate

    public func peripheralConnected() {
        // will be called BEFORE pairing
    }

    public func peripheralDisconnected(peripheral: CBPeripheral, error: Error?) {
        deviceDisconnectedCallback(error)
        if let error = error {
            continuation?.resume(throwing: error)
        }
    }

    public func peripheralFailedToConnect(peripheral: CBPeripheral?, error: Error?) {
        deviceDisconnectedCallback(error)
        if let error = error {
            continuation?.resume(throwing: error)
        }
    }

    // MARK: ESPDeviceConnectionDelegate

    func getProofOfPossesion(forDevice: ESPProvision.ESPDevice, completionHandler: @escaping (String) -> Void) {
        completionHandler(pop ?? "")
    }

    func getUsername(forDevice: ESPProvision.ESPDevice, completionHandler: @escaping (String?) -> Void) {
        completionHandler(username)
    }
}

extension ESPDevice {
    func scanWifiList() async throws -> [ESPWifiNetwork] {
        try await withCheckedThrowingContinuation({ continuation in
            self.scanWifiList { networks, error in
                if let error = error {
                    // ignore other error types such as SwiftProtobuf.BinaryDecodingError.malformedProtobuf
                    // which will cause multiple calls of the completionHandler!
                    if case let ESPWiFiScanError.scanRequestError(otherError) = error, case SwiftProtobuf.BinaryDecodingError.malformedProtobuf = otherError {
                        return
                    }

                    // an empty wifi list is not an scan error, don't throw.
                    if case ESPWiFiScanError.emptyResultCount = error {
                        continuation.resume(returning: [])
                    } else {
                        continuation.resume(throwing: error)
                    }
                } else {
                    continuation.resume(returning: networks ?? [])
                }
            }
        })
    }

    func provision(ssid: String, password: String) async throws -> Void {
        try await withCheckedThrowingContinuation({ continuation in
            self.provision(ssid: ssid, passPhrase: password) { status in
                switch status {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                case .configApplied:
                    break
                }
            }
        })
    }

    func sendData(path: String, data: Data) async throws -> Data? {
        try await withCheckedThrowingContinuation({ continuation in
            self.sendData(path: path, data: data) { data, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: data)
                }
            }
        })
    }
}
