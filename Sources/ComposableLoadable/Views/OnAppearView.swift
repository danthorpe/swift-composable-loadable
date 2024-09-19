import SwiftUI

public struct OnAppearView: View {
  let block: @MainActor () -> Void
  public var body: some View {
    Color.clear.onAppear(perform: block)
  }
}
