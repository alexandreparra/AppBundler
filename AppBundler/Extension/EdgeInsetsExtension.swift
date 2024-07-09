import SwiftUI

extension EdgeInsets {
    static func all(padding: CGFloat) -> EdgeInsets {
        return EdgeInsets(top: padding, leading: padding, bottom: padding, trailing: padding)
    }
}
