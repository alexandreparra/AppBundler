//
//  BundleExtension.swift
//  AppBundler
//  Created on 15/04/24.
//

import Foundation

extension Bundle {
    static func localizedString(forKey key: String) -> String {
        return Bundle
            .main
            .localizedString(forKey: key, value: nil, table: nil)
    }
}
