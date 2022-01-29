import Foundation

// See: https://drewdeponte.com/blog/swift-failable-decodable/
extension Result: Decodable where Success: Decodable, Failure == DecodingError {
  public init(from decoder: Decoder) throws {
    do {
      let container = try decoder.singleValueContainer()
      self = .success(try container.decode(Success.self))
    } catch let err as Failure {
      self = .failure(err)
    }
  }
}
