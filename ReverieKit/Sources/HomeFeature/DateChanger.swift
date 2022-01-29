import SwiftDate
import SwiftUI

struct DateChanger: View {
  @Binding var date: Date

  var body: some View {
    DatePicker(
      "Selected date",
      selection: $date,
      displayedComponents: [.date]
    )
    .datePickerStyle(.graphical)
    .padding()
  }
}

struct DateChanger_Previews: PreviewProvider {
  static var previews: some View {
    DateChanger(date: Binding.constant(Date()))
  }
}
