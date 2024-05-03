import SwiftUI

public struct OnAppearView: View {
  let block: () -> Void
  public var body: some View {
    Color.clear.onAppear(perform: block)
  }
}
