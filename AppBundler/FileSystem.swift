import AppKit
import Foundation
import UniformTypeIdentifiers

enum BinaryType {
    case exec, jar
}

/// Determine the binary type to create a bundle from based on its name.
func determineBinaryType(binaryName: String) -> BinaryType {
    let fileComponents = binaryName.split(separator: ".")
    if (fileComponents.count < 2) {
        return .exec
    }
    
    if fileComponents.last == "jar" {
        return .jar
    }
    
    return .exec
}

func createNSBundle(
    at bundlePath: String,
    withName bundleName: String,
    binaryPath: String,
    iconLocation: String
) -> Bool {
    assert(!bundlePath.isEmpty)
    assert(!bundleName.isEmpty)
    assert(!binaryPath.isEmpty)
    
    let fileManager = FileManager.default
    guard let bundle = Bundle.create(atPath: bundlePath, bundleName: bundleName) else {
        return false
    }
    
    let binaryURL = URL(filePath: binaryPath)
    let binaryName = binaryURL.lastPathComponent
    let binaryType = determineBinaryType(binaryName: binaryName)
    writeBinary(binaryURL, toBundle: bundle, binaryType: binaryType)
    
    if !iconLocation.isEmpty {
        if var resourcesURL = bundle.resourceURL {
            let iconURL = URL(filePath: iconLocation)
            let iconName = renameFile(at: iconURL, newName: "AppIcon")
            resourcesURL.append(path: iconName)
            try? fileManager.copyItem(at: iconURL, to: resourcesURL)
        }
    }
    
    return writePList(
        at: bundle.contentsPath(),
        appName: bundleName,
        binaryName: bundleName,
        iconName: "AppIcon"
    )
}

/// Write the binary to the standard `BundleName`/Contents/MacOS executable folder.
/// If the executable in question is a .jar, them an extra script will be copie to the folder alongside.
func writeBinary(_ binaryURL: URL, toBundle bundle: Bundle, binaryType: BinaryType) {
    let binaryName = binaryURL.lastPathComponent
    var bundleBinaryPathURL = bundle.macosURL()
    bundleBinaryPathURL.append(path: binaryName)
    
    try? FileManager.default.copyItem(at: binaryURL, to: bundleBinaryPathURL)
    
    if binaryType == .jar {
        let shellScript = """
        #!/bin/bash
        SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
        cd $SCRIPT_DIR
        java -jar ./\(binaryName)
        """
        
        let shellScriptName = bundle.name()
        var scriptURL = bundle.macosURL()
        scriptURL.append(path: shellScriptName)
        FileManager.default.createFile(
            atPath: scriptURL.path(percentEncoded: false),
            contents: shellScript.data(using: .utf8),
            attributes: [ FileAttributeKey.posixPermissions: 0o755 ]
        )
    }
}

// Output example (Info.plist):
// <key>CFBundleDisplayName</key>
// <string>$appName</string>
// <key>CFBundleExecutable</key>
// <string>$binaryName</string>
// <key>CFBundleIconFile</key>
// <string>$iconName</string>
func writePList(
    at bundleContentsPath: String,
    appName: String,
    binaryName: String,
    iconName: String
) -> Bool {
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

func updateBundle(
    _ bundleInfo: BundleInfo,
    newBundleName: String,
    newBundleIconPath: String
) {
    guard let bundle = Bundle(url: URL(filePath: bundleInfo.path)) else { return }
    guard var plist = bundle.infoDictionary as? [String: String] else { return }
    plist.updateValue(newBundleName, forKey: "CFBundleDisplayName")
    
    let fileManager = FileManager.default
    do {
        let plistEncoder = PropertyListEncoder()
        let data = try plistEncoder.encode(plist)
        
        var contentsURL = bundle.bundleURL
        contentsURL.append(path: "Contents")
        contentsURL.append(path: "Info.plist")
        try data.write(to: contentsURL)
        
        var renamedBundle = bundle.bundleURL.deletingLastPathComponent()
        renamedBundle.append(path: newBundleName + ".app")
        try fileManager.moveItem(at: bundle.bundleURL, to: renamedBundle)
    } catch {
    }
    
    if newBundleIconPath.isNotEmpty() {
        var bundleResourcesURL = bundle.resourceURL!.absoluteURL
        let newIconURL = URL(filePath: newBundleIconPath)
        
        var iconName = plist["CFBundleIconFile"] as? String
            ?? plist["CFBundleURLIconFile"] as? String
            ?? ""
        
        if iconName != "" {
            // Try to discover the file extension
            let files = try? fileManager.contentsOfDirectory(
                atPath: bundleResourcesURL.path(percentEncoded: false)
            )
            if let files, !files.isEmpty {
                // Find the file with its extension inside the Resources folder, if any.
                let iconNameOnFolder = findFileInside(folderContents: files, iconName: iconName)
                var iconURL = bundleResourcesURL
                iconURL.append(path: iconNameOnFolder)
                try? fileManager.removeItem(at: iconURL)
                
                // Extensions may differ between the new and old icon.
                let newIconExtension = newIconURL.pathExtension
                var destinationURL = bundleResourcesURL
                destinationURL.append(
                    path: renameFile(at: newIconURL, newName: "AppIcon", ext: newIconExtension)
                )
                try? fileManager.copyItem(
                    atPath: newBundleIconPath,
                    toPath: destinationURL.path(percentEncoded: false)
                )
                return
            }
        }
        
        var destinationURL = bundleResourcesURL
        destinationURL.append(path: renameFile(at: newIconURL, newName: "AppIcon"))
        // For some reason, using URL's doesn't work
        try? fileManager.copyItem(
            atPath: newIconURL.path(percentEncoded: false),
            toPath: destinationURL.path(percentEncoded: false)
        )
    }
}

/// Given a list of strings that represent folders and files, find a file that has any type of extension based on
/// `iconName`
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

func renameFile(at file: URL, newName: String, ext: String) -> String {
     assert(!newName.isEmpty)
    
    let newFileName = "\(newName).\(ext)"
    return newFileName
}

func chooseSaveFolder() -> String {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    if panel.runModal() == .OK {
        return panel.url?.path ?? ""
    }
    
    return ""
}

func chooseIcon() -> String {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.allowedContentTypes = [.jpeg, .png, .ico, .svg, .pdf, .webP]
    if panel.runModal() == .OK {
        return panel.url?.path ?? ""
    }
    
    return ""
}

func chooseFile() -> String {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    if panel.runModal() == .OK {
        return panel.url?.path ?? ""
    }
    
    return ""
}

func chooseBundle() -> String {
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
