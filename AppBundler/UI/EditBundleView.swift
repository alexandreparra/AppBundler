//
//  EditBundleView.swift
//  AppBundler
//  Created on 17/03/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct BundleInfo {
    var path: String
    var name: String
    var iconPath: String
}

enum LoadBundleState {
    case success(BundleInfo)
    case failure(String)
    case imageFailure(BundleInfo)
}

struct EditBundleView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @State private var newBundleName = ""
    @State private var disableUpdateButton = true
    
    var body: some View {
        Form {
            if (appState.bundleInfo.path.isEmpty) {
                Button("Choose Bundle") {
                    let bundlePath = findBundleFolder()
                    if (bundlePath != "") {
                        let loadBundleState = loadBundleInfo(from: bundlePath)
                        switch loadBundleState {
                        case .success(let bundleInfo):
                            self.appState.bundleInfo = bundleInfo
                            self.newBundleName = bundleInfo.name
                            self.loadImage()
                        case .imageFailure(let bundleInfo):
                            self.appState.bundleInfo = bundleInfo
                            self.newBundleName = bundleInfo.name
                            self.loadImage()
                        case .failure(let errorMessage):
                            alertMessage = errorMessage
                            showAlert = true
                        }
                    }
                }
            } else {
                HStack {
                    Text("Bundle name:")
                    TextField("", text: $newBundleName).onChange(of: newBundleName, {
                        didInfoChange()
                    })
                }
                
                HStack {
                    Text("Icon:")
                    self.appState.image
                        .resizable()
                        .frame(maxWidth: 72, maxHeight: 72)
                        .padding(EdgeInsets.all(padding: 2))
                        .dropDestination(for: URL.self) { items, location in
                            guard let item = items.first else { return false }
                            
                            let nsImage = NSImage(contentsOf: item)
                            guard let nsImage else { return false }
                            
                            self.appState.image = Image(nsImage: nsImage)
                            return true
                        }
                        .background(
                            Color(red: 0.43, green: 0.42, blue: 0.44), // Darker gray
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .help(self.appState.bundleInfo.iconPath.isEmpty ? "Couldn't find bundle image" : "")
                }
                
                HStack {
                    Button {
                        self.appState.bundleInfo = BundleInfo(path: "", name: "", iconPath: "")
                    } label: {
                        Text("Cancel").foregroundStyle(.red)
                    }
                    Button("Update bundle") {
                        updateBundle(self.appState.bundleInfo, newBundleName: newBundleName)
                    }.disabled(disableUpdateButton)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("Retry", role: .cancel) {}
        }
        .padding()

    }
    
    func loadImage() {
        if let img = NSImage(contentsOfFile: appState.bundleInfo.iconPath) {
            appState.image = Image(nsImage: img)
        } else {
            appState.image = Image(systemName: "exclamationmark.triangle.fill")
        }
    }
    
    func didInfoChange() {
        self.disableUpdateButton = self.newBundleName.isEmpty ||
                                   self.newBundleName == self.appState.bundleInfo.name
    }
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

#Preview {
    EditBundleView()
}
