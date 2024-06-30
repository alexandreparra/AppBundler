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
                        infoDidChange()
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
    
    func infoDidChange() {
        self.disableUpdateButton = self.newBundleName.isEmpty ||
                                   self.newBundleName == self.appState.bundleInfo.name
    }
}

#Preview {
    EditBundleView()
}
