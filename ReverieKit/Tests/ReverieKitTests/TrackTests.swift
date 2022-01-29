import Foundation
import ReverieKit
import SharedModels
import XCTest

class TrackTests: XCTestCase {
  var data: Data!

  override func setUp() async throws {
    let url = Bundle.module.url(forResource: "tracks", withExtension: "json")!
    data = try Data(contentsOf: url)
  }

  func testDecodingArrayOfTrackJSON() throws {
    let decoder = JSONDecoder()
    do {
      let tracks = try decoder.decode([Track].self, from: data)
      XCTAssertEqual(tracks.count, 29)

      let track = tracks.first
      XCTAssertEqual(track?.name, "Stayin' Alive")
      XCTAssertEqual(track?.artistName, "Bee Gees")
      XCTAssertEqual(track?.albumName, "Tales from the Brothers Gibb")
      XCTAssertEqual(track?.date, Date(timeIntervalSince1970: 1_534_528_354))
      XCTAssertEqual(
        track?.imageUrl?.absoluteString,
        "https://lastfm.freetls.fastly.net/i/u/300x300/d9ad88ec12801b2cfdb82507f889c208.jpg"
      )
    } catch {
      XCTFail("Caught JSONDeoder error: \(error)")
    }
  }
}
