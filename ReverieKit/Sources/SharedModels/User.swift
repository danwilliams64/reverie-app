import Foundation

public struct User: Codable, Identifiable, Equatable {
  public var id: String {
    username
  }

  public let username: String
  public let realName: String?
  public let url: URL?
  public let imageUrl: URL?
}

extension User: CustomStringConvertible {
  public var description: String {
    "Username: \(username)"
  }
}

public extension User {
  private enum CodingKeys: String, CodingKey {
    case name, realname, url, image
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    username = try container.decode(String.self, forKey: .name)
    realName = try container.decodeIfPresent(String.self, forKey: .realname)
    url = try container.decodeIfPresent(URL.self, forKey: .url)
    let images = try container.decodeIfPresent([Image].self, forKey: .image)
    imageUrl = images?.last?.url
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(username, forKey: .name)
    try container.encode(realName, forKey: .realname)
    try container.encode(url, forKey: .url)
    try container.encode([Image(size: .extralarge, url: imageUrl)], forKey: .image)
  }
}

public extension User {
  static let mock = Self(username: "djw657", realName: "Mock", url: nil, imageUrl: nil)
}
