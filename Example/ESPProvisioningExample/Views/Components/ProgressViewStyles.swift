import SwiftUI

 struct BackdropProgressViewStyle: ProgressViewStyle {
     func makeBody(configuration: Configuration) -> some View {
         ProgressView(configuration)
             .progressViewStyle(CircularProgressViewStyle(tint: .white))
             .padding()
             .background(Color.secondary)
             .clipShape(RoundedRectangle(cornerRadius: 10))
     }
 }

struct Block: ViewModifier {
    let block: Bool
    let message: String?

    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(block ? 0.25 : 1.0)
                .disabled(block)

            if block {
                ProgressView {
                    if let message = message {
                        Text(message)
                            .foregroundColor(.primary)
                    }
                }
                .progressViewStyle(BackdropProgressViewStyle())
            }
        }
    }
}

struct Blocked<T: Any>: ViewModifier {
    let state: Binding<T>
    let callback: (T) -> (Bool, String?)

    func body(content: Content) -> some View {
        let result = callback(state.wrappedValue)
        let block = result.0 == true
        let message = result.1

        ZStack {
            content
                .opacity(block ? 0.25 : 1.0)
                .disabled(block)

            if block {
                ProgressView {
                    if let message = message {
                        Text(message)
                            .foregroundColor(.primary)
                    }
                }
                .progressViewStyle(BackdropProgressViewStyle())
            }
        }
    }
}

extension View {
    func blocked<T>(_ state: Binding<T>, evaluate: @escaping (T) -> (Bool, String?)) -> some View {
        modifier(Blocked(state: state, callback: evaluate))
    }

    func isBlocked(_ block: Bool, message: String?) -> some View {
        modifier(Block(block: block, message: message))
    }
}

struct ProgressView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressView() {
            Text("Preview")
        }
        .progressViewStyle(BackdropProgressViewStyle())
    }
}
