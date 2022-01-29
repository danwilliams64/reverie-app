import SwiftUI

struct EmptyContentView: View {
  var username: String?

  var body: some View {
    VStack(spacing: 8) {
      Text("No Scrobbles Found")
        .font(.title2)
        .fontWeight(.semibold)
      Text(
        "\(username ?? "This user") may have chosen to keep their listening information private."
      )
      .fontWeight(.medium)
      .multilineTextAlignment(.center)
      .foregroundColor(Color(uiColor: .secondaryLabel))
      .padding()
    }
  }
}

struct EmptyContentView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      EmptyContentView(username: "Daisy_Anna")
        .navigationTitle("Reverie")
    }
    .preferredColorScheme(.dark)
  }
}
