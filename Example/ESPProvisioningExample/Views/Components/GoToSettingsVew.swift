import SwiftUI

struct GoToSettingsVew: View {
    let image: Image
    let message: String
    var body: some View {
        VStack(spacing: 40) {
            image
                .resizable()
                .scaledToFit()
                .frame(width: 150)
                .opacity(0.5)

            Text(message)
                .font(.footnote)
                .multilineTextAlignment(.center)

            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }, label: {
                Text("Settings")
            })
        }
    }
}
