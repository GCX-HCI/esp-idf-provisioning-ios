import SwiftUI

enum Message {
    case error(LocalizedError)
    case success(String)
}

struct MessageAlert: ViewModifier {
    let message: Binding<Message?>
    let action: ((Message) -> Void)?
    let messageValue: Message?

    init(message: Binding<Message?>, action:((Message) -> Void)?) {
        self.message = message
        self.action = action
        self.messageValue = message.wrappedValue
    }

    func body(content: Content) -> some View {
        let dismissButton = Alert.Button.default(Text("OK")) {
            if let messageValue = messageValue {
                action?(messageValue)
            }
        }

        let binding = Binding<Bool> {
            return message.wrappedValue != nil
        } set: { val in
            if val == false {
                message.wrappedValue = nil
            }
        }

        let alert: Alert? = {
            switch message.wrappedValue {
            case .error(let error):
                return Alert(title: Text("Error"), message: Text(error.localizedDescription), dismissButton: dismissButton)
            case .success(let message):
                return Alert(title: Text("Success"), message: Text(message), dismissButton: dismissButton)
            case .none:
                return nil
            }
        }()

        content
            .alert(isPresented: binding) { alert ?? Alert(title: Text("none")) }
    }
}

extension View {
    func messageAlert(_ message: Binding<Message?>, action: ((Message) -> Void)? = nil) -> some View {
        modifier(MessageAlert(message: message, action: action))
    }
}
