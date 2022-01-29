import SwiftUI

public struct CoverArt: View {
  public var url: URL?

  public init(url: URL?) {
    self.url = url
  }

  public var body: some View {
    AsyncImage(url: url) { image in
      image.resizable()
    } placeholder: {
      Rectangle()
        .fill(Color(.systemFill))
    }
    .aspectRatio(1, contentMode: .fit)
    .border(Color(white: 1, opacity: 0.15), width: 1)
    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
  }
}
