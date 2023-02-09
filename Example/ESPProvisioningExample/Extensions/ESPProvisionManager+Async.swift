import ESPProvision
import UIKit.UIView
import AVFoundation

extension ESPProvisionManager {
    func searchESPDevices(prefix: String) async throws -> [ESPDevice] {
        try await withCheckedThrowingContinuation({ continuation in
            ESPProvisionManager.shared.searchESPDevices(devicePrefix: prefix, transport: .ble, security: .secure) { bleDevices, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: bleDevices ?? [])
                }
            }
        })
    }

    func scanQRCode(scanView: UIView, scanStatusCallback: @escaping (ESPScanStatus) -> Void) async throws -> ESPDevice {
        try await withCheckedThrowingContinuation { continuation in
            ESPProvisionManager.shared.scanQRCode(scanView: scanView, completionHandler:
                                                    { espDevice, espDeviceCSSError in
                                                        if let error = espDeviceCSSError {
                                                            continuation.resume(throwing: error)
                                                        } else {
                                                            guard let espDevice = espDevice else {
                                                                continuation.resume(throwing: ESPDeviceCSSError.espDeviceNotFound)
                                                                return
                                                            }

                                                            continuation.resume(returning: espDevice)
                                                        }
                                                    }
                                                    , scanStatus: scanStatusCallback)
        }
    }

    func getCameraAuthorizationStatus() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
            case .authorized:
                continuation.resume(returning: true)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(throwing: ESPDeviceCSSError.cameraAccessDenied)
                    }
                }
            case .denied, .restricted:
                continuation.resume(throwing: ESPDeviceCSSError.cameraAccessDenied)
            default:
                continuation.resume(throwing: ESPDeviceCSSError.cameraNotAvailable)
            }
        }
    }
}
