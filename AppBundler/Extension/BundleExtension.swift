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
    
    /// Create an NSBundle for the given path
    static func create(atPath bundlePath: String, bundleName: String) -> Bundle? {
        let fileManager = FileManager.default
        
        var bundlePathURL = URL(filePath: bundlePath)
        bundlePathURL.append(path: bundleName)
        bundlePathURL.appendPathExtension("app")
        
        var contentsPath = URL(filePath: bundlePathURL.absoluteString)
        contentsPath.append(path: "Contents")
        
        var resourcesPath = URL(filePath: contentsPath.absoluteString)
        resourcesPath.append(path: "Resources")
        try? fileManager.createDirectory(at: resourcesPath, withIntermediateDirectories: true)
        
        var binaryFolderURL = URL(filePath: contentsPath.absoluteString)
        binaryFolderURL.append(path: "MacOS")
        try? fileManager.createDirectory(at: binaryFolderURL, withIntermediateDirectories: true)
        
        return Bundle(path: bundlePathURL.path(percentEncoded: false))
    }
    
    func macosURL() -> URL {
        var url = URL(filePath: self.contentsPath())
        url.append(path: "MacOS")
        return url
    }
    
    func macosPath() -> String {
        return self.macosURL().path(percentEncoded: false)
    }
    
    func contentsURL() -> URL {
        var url = URL(filePath: self.bundlePath)
        url.append(path: "Contents")       
        return url
    }
   
    func contentsPath() -> String {
        return self.contentsURL().path(percentEncoded: false)
    }
    
    func name() -> String {
        return self.bundleURL.lastPathComponent.split(separator: ".").first?.toString() ?? ""
    }
}
