import ESPProvision
import Foundation

enum GenericError: LocalizedError {
    case some(Error)

    public var errorDescription: String? {
        switch self {
        case .some(let error):
            return error.localizedDescription
        }
    }
}

extension ESPProvision.ESPDeviceCSSError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .espDeviceNotFound:
            return "Device not found. Please make sure the device is turned on, the name matches the name defined in the QR code or you are using the correct prefix if connecting manually"
        default:
            return "Device error"
        }
    }
}

extension ESPProvision.ESPSessionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .bleFailedToConnect:
            return "Disconnect during connection attempt, or device not found"
        case .sessionInitError:
            return "Session coud not be initialized. Make sure security version and credentials match"
        default:
            return "Failed initializing session"
        }
    }
}

extension ESPProvision.ESPProvisionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .wifiStatusAuthenticationError:
            return "Wrong Wi-Fi credentials"
        default:
            return "Provisioning failed"
        }
    }
}
