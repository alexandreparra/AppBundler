//
//  FileSystem.swift
//  AppBundler
//  Created on 20/03/24.
//

import AppKit
import Foundation
import UniformTypeIdentifiers

func createBundle(at bundlePath: String, withName bundleName: String, binaryPath: String, iconLocation: String) -> Bool {
    assert(!bundlePath.isEmpty)
    assert(!bundleName.isEmpty)
    assert(!binaryPath.isEmpty)
    
    let fileManager = FileManager.default
    
    var bundlePathURL = URL(filePath: bundlePath)
    bundlePathURL.append(path: bundleName)
    bundlePathURL.appendPathExtension("app")
    
    var contentsPath = URL(filePath: bundlePathURL.absoluteString)
    contentsPath.append(path: "Contents")
    
    // Binary
    var binaryFolderURL = URL(filePath: contentsPath.absoluteString)
    binaryFolderURL.append(path: "MacOS")
    try? fileManager.createDirectory(at: binaryFolderURL, withIntermediateDirectories: true)
    
    let binaryURL = URL(filePath: binaryPath)
    let binaryName = binaryURL.lastPathComponent
    binaryFolderURL.append(path: binaryName)
    try? fileManager.copyItem(at: binaryURL, to: binaryFolderURL)

    // Icon
    if !iconLocation.isEmpty {
        var resourcesPath = URL(filePath: contentsPath.absoluteString)
        resourcesPath.append(path: "Resources")
        try? fileManager.createDirectory(at: resourcesPath, withIntermediateDirectories: true)

        let iconURL = URL(filePath: iconLocation)
        let iconName = renameFile(at: iconURL, newName: "AppIcon")
        resourcesPath.append(path: iconName)
        try? fileManager.copyItem(at: iconURL, to: resourcesPath)
    }
   
    #if DEBUG
    print(#function)
    print("Contents folder path:  \(contentsPath)")
    print("Binary folder path:    \(binaryFolderURL.absoluteString)")
    print("Binary path:           \(binaryPath)")
    print("Icon path              \(iconLocation)")
    print()
    #endif
   
    return writePList(
        at: contentsPath.absoluteString,
        appName: bundleName,
        binaryName: binaryName,
        iconName: "AppIcon"
    )
}

// Output example (Info.plist):
// <key>CFBundleDisplayName</key>
// <string>$appName</string>
// <key>CFBundleExecutable</key>
// <string>$appName</string>
// <key>CFBundleIconFile</key>
// <string>$iconName</string>
func writePList(at bundleContentsPath: String, appName: String, binaryName: String, iconName: String) -> Bool {
    let plist = [
        "CFBundleDisplayName": appName,
        "CFBundleExecutable": binaryName,
        "CFBundleIconFile": iconName
    ]
    
    var plistPathURL = URL(filePath: bundleContentsPath)
    plistPathURL.append(path: "Info.plist")
    
    do {
        let fileManager = FileManager.default
        fileManager.createFile(atPath: plistPathURL.path(percentEncoded: false), contents: nil)
        
        let plistEncoder = PropertyListEncoder()
        let data = try plistEncoder.encode(plist)
        try data.write(to: plistPathURL)
        
        #if DEBUG
        print(#function)
        print("Contents folder path: \(bundleContentsPath)")
        print("PList path:           \(plistPathURL.path())")
        #endif
    } catch {
        #if DEBUG
        print(#function)
        print("Error writing plist at: \(plistPathURL.path())")
        print(error)
        #endif
        return false
    }
    
    return true
}

/// Change the file name, preserving its extension
func renameFile(at file: URL, newName: String) -> String {
    assert(!newName.isEmpty)
    
    let fileExtension = file.pathExtension
    let newFileName = "\(newName).\(fileExtension)"
    return newFileName
}

func chooseFolder() -> String {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    if panel.runModal() == .OK {
        return panel.url?.path ?? ""
    }
    
    return ""
}

func findIconPath() -> String {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    if panel.runModal() == .OK {
        return panel.url?.path ?? ""
    }
    
    return ""
}

func findBundleFolder() -> String {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.allowedContentTypes = [UTType.bundle]
    if panel.runModal() == .OK {
        return panel.url?.path ?? ""
    }
    
    return ""
}
