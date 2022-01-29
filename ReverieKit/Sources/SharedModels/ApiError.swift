import Foundation

public struct ApiError: Codable, Error, Equatable, LocalizedError {
  public let errorDump: String
  public let file: String
  public let line: UInt
  public let message: String

  public init(
    error: Error,
    file: StaticString = #fileID,
    line: UInt = #line
  ) {
    var string = ""
    dump(error, to: &string)
    errorDump = string
    self.file = String(describing: file)
    self.line = line
    message = error.localizedDescription
  }

  public var errorDescription: String? {
    message
  }
}
