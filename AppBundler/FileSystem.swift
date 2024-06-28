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

// Bundle icon scenarios:
// 1. Icon name is inside CFBundleIconFile but the "Resources" directory doesn't contain any file: FAIL
// 2. No Icon name on CFBundleIconFiel: FAIL
// 3. Icon name is inside CFBundleIconFile but the icon name doesn't contain any extensions like: ".icsn"
//    3.1 "Resources" directory doesn't contain any files: FAIL
//    3.2 "Resources" directoy contain files and the icon name is contained inside
//         it but doesn't have any extension (like listed on the plist): SUCCESS
//    3.3 "Resources" directory contain files and the icon name has a different extension
//        from what is provided at CFBundleIconFile,
// 4. Icon name is inside CFBundleIconFile and has extension: SUCCESS
func loadBundleInfo(from bundlePath: String) -> LoadBundleState {
    let bundleURL = URL(filePath: bundlePath)
    let bundle = Bundle(url: bundleURL)
    guard let bundle else {
        #if DEBUG
        print(#function)
        print("BUNDLE NOT FOUND AT: \(bundleURL.path(percentEncoded: false))")
        #endif
        
        return .failure(Bundle.localizedString(forKey: "EditBundleError01"))
    }
    
    let plist = bundle.infoDictionary
    guard let plist else {
        #if DEBUG
        print(#function)
        print("PLIST NOT FOUND FOR BUNDLE AT: \(bundleURL.path(percentEncoded: false))")
        #endif
        
        return .failure(Bundle.localizedString(forKey: "EditBundleError02"))
    }
    
    let fileManager = FileManager.default
    
    var bundleName = plist["CFBundleDisplayName"] as? String ?? ""
    if bundleName.isEmpty {
        bundleName = plist["CFBundleName"] as? String ?? ""
    }
    
    let resourcesPath = bundle.resourcePath
    if resourcesPath == nil || !fileManager.fileExists(atPath: resourcesPath!) {
        #if DEBUG
        print(#function)
        print("RESOUCE FOLDER NOT FOUND FOR BUNDLE AT: \(bundleURL.path(percentEncoded: false))")
        #endif
        return .imageFailure(BundleInfo(path: bundlePath, name: bundleName, iconPath: ""))
    }
    
    var iconPath = plist["CFBundleIconFile"] as? String
        ?? plist["CFBundleURLIconFile"] as? String
        ?? ""
    
    if iconPath != "" {
        if let files = try? fileManager.contentsOfDirectory(atPath: resourcesPath!) {
            let iconName = findFileInside(folderContents: files, iconName: iconPath)
            var iconURL = URL(filePath: resourcesPath!)
            iconURL.append(path: iconName)
            iconPath = iconURL.path(percentEncoded: false)
        } else {
            iconPath = ""
        }
    }
    
    #if DEBUG
    print(#function)
    print("Contents bundle folder: \(bundleURL.path())")
    print(plist)
    print("Bundle name:            \(bundleName)")
    print("Icon path:              \(iconPath)")
    #endif
    
    return .success(BundleInfo(path: bundlePath, name: bundleName, iconPath: iconPath))
}

func updateBundle(_ bundleInfo: BundleInfo, newBundleName: String) {
    guard let bundle = Bundle(url: URL(filePath: bundleInfo.path)) else { return }
    var plist = bundle.infoDictionary as? [String: String]
    plist?.updateValue(newBundleName, forKey: "CFBundleDisplayName")
    
    do {
        let plistEncoder = PropertyListEncoder()
        let data = try plistEncoder.encode(plist)
        
        var contentsURL = bundle.bundleURL
        contentsURL.append(path: "Contents")
        contentsURL.append(path: "Info.plist")
        try data.write(to: contentsURL)
        
        let fileManager = FileManager.default
        var renamedBundle = bundle.bundleURL.deletingLastPathComponent()
        renamedBundle.append(path: newBundleName + ".app")
        try fileManager.moveItem(at: bundle.bundleURL, to: renamedBundle)
    } catch {
    }

}

func findFileInside(folderContents: [String], iconName: String) -> String {
    if iconName.isEmpty { return "" }
    
    if iconName.split(separator: ".").count < 2 {
        if !folderContents.isEmpty {
            for file in folderContents {
                if file == iconName {
                    // File doesn't contain any extension, OK.
                    return iconName
                }
                
                let fileComponents = file.split(separator: ".")
                if !fileComponents.isEmpty && fileComponents[0] == iconName {
                    return file
                }
            }
        }
    } else {
        return iconName
    }

    return ""
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
