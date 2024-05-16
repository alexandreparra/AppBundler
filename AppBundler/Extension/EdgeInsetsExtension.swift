//
//  EdgeInsetsExtension.swift
//  AppBundler
//  Created on 05/04/24.
//

import SwiftUI

extension EdgeInsets {
    static func all(padding: CGFloat) -> EdgeInsets {
        return EdgeInsets(top: padding, leading: padding, bottom: padding, trailing: padding)
    }
}
