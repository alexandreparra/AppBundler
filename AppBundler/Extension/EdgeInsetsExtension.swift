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

extension String {
    func ends(with sequence: String) -> Bool {
        let pathComponent = self.split(whereSeparator: { $0 == "."})
        if pathComponent.isEmpty {
            return false
        }
        
        return sequence == pathComponent[0]
    }
}
