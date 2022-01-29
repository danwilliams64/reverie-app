import Foundation
import SwiftUI

public extension Image {
  enum SFSymbol: String {
    case applelogo
    case arrowRight = "arrow.right"
    case calendar
    case checkmarkCircleFill = "checkmark.circle.fill"
    case chevronDown = "chevron.down"
    case chevronRight = "chevron.right"
    case gearshape
    case squareAndPencil = "square.and.pencil"
    case trash
    case xmark
  }

  init(sfSymbol: SFSymbol) {
    self.init(systemName: sfSymbol.rawValue)
  }
}
