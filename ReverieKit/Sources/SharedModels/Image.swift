import Foundation

struct Image: Codable {
  private enum ImageCodingKeys: String, CodingKey {
    case size
    case text = "#text"
  }

  enum Size: String, Decodable {
    case small, medium, large, extralarge
  }

  let size: Size
  let url: URL?

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: ImageCodingKeys.self)
    size = try container.decode(Image.Size.self, forKey: .size)
    url = try container.decodeIfPresent(URL.self, forKey: .text)
  }

  init(size: Size, url: URL?) {
    self.size = size
    self.url = url
  }
}

extension Image {
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: ImageCodingKeys.self)

    try container.encode(size.rawValue, forKey: .size)
    try container.encode(url, forKey: .text)
  }
}
