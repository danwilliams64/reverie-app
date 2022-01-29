import Foundation
import SwiftUI

// See https://www.donnywals.com/using-uisheetpresentationcontroller-in-swiftui/

struct BottomSheetPresenter<Content>: UIViewRepresentable where Content: View {
  let label: String
  let content: Content
  let detents: [UISheetPresentationController.Detent]

  init(
    _ label: String,
    detents: [UISheetPresentationController.Detent],
    @ViewBuilder content: () -> Content
  ) {
    self.label = label
    self.content = content()
    self.detents = detents
  }

  func makeUIView(context _: UIViewRepresentableContext<BottomSheetPresenter>) -> some UIButton {
    let button = UIButton(type: .system)
    button.setTitle(label, for: .normal)
    button.addAction(UIAction { _ in
      let hostingController = UIHostingController(rootView: content)
      let viewController = BottomSheetWrapperController(detents: detents)
      viewController.view.backgroundColor = .red

      viewController.addChild(hostingController)
      viewController.view.addSubview(hostingController.view)
      hostingController.view.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor)
        .isActive = true
      hostingController.view.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor)
        .isActive = true
      hostingController.view.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        .isActive = true
      hostingController.view.topAnchor.constraint(equalTo: viewController.view.topAnchor)
        .isActive = true
      hostingController.didMove(toParent: viewController)

      button.window?.rootViewController?.present(viewController, animated: true)
    }, for: .touchUpInside)
    return button
  }

  func updateUIView(_: UIViewType, context _: Context) {
    // no updates
  }

  func makeCoordinator() {
    ()
  }
}

class BottomSheetWrapperController: UIViewController {
  let detents: [UISheetPresentationController.Detent]

  init(detents: [UISheetPresentationController.Detent]) {
    self.detents = detents
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("No Storyboards")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    if let sheetController = presentationController as? UISheetPresentationController {
      sheetController.detents = detents
      sheetController.prefersGrabberVisible = true
    }
  }
}
