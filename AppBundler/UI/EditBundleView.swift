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
    
    @State private var imageChange = ""
    
    var body: some View {
        Form {
            if (appState.bundleInfo.path.isEmpty) {
                Button("Choose Bundle") {
                    self.chooseBundleFolder()
                }
            } else {
                HStack {
                    Text("Bundle name:")
                    TextField(
                        "",
                        text: self.$appState.newBundleName
                    )
                    .onChange(of: self.appState.newBundleName, {
                        self.appState.infoDidChange()
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
                            
                            self.appState.newIconPath = item.path(percentEncoded: false)
                            self.appState.image = Image(nsImage: nsImage)
                            self.appState.infoDidChange()
                            
                            return true
                        }
                        .background(
                            Color(red: 0.43, green: 0.42, blue: 0.44), // Darker gray
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .help(
                            self.appState.bundleInfo.iconPath.isEmpty
                            ? "Couldn't find bundle image" : ""
                        )
                        .onTapGesture {
                            changeImage()
                        }
                }
                
                HStack {
                    Button {
                        self.appState.resetInspectBundleState()
                    } label: {
                        Text("Cancel").foregroundStyle(.red)
                    }
                    Button("Update bundle") {
                        updateBundle(
                            self.appState.bundleInfo,
                            newBundleName: self.appState.newBundleName,
                            newBundleIconPath: self.appState.newIconPath
                        )
                        self.showSuccessAlert()
                    }.disabled(self.appState.disableUpdateButton)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                self.appState.resetInspectBundleState()
            }
        }
        .padding()
    }
    
    private func showSuccessAlert() {
        showAlert = true
        alertMessage = "Bundle updated succesfully!"
    }
    
    private func changeImage() {
        let iconPath = chooseIcon()
        if iconPath != "" {
            if let nsImage = NSImage(contentsOfFile: iconPath) {
                self.appState.newIconPath = iconPath
                self.appState.image = Image(nsImage: nsImage)
            }
        }
        self.appState.infoDidChange()
    }
    
    private func loadImage() {
        if let img = NSImage(contentsOfFile: appState.bundleInfo.iconPath) {
            appState.image = Image(nsImage: img)
        } else {
            appState.image = Image(systemName: "exclamationmark.triangle.fill")
        }
    }
    
    private func chooseBundleFolder() {
        let bundlePath = chooseBundle()
        if (bundlePath != "") {
            let loadBundleState = loadBundleInfo(from: bundlePath)
            switch loadBundleState {
            case .success(let bundleInfo):
                self.appState.bundleInfo = bundleInfo
                self.appState.newBundleName = bundleInfo.name
                self.loadImage()
            case .imageFailure(let bundleInfo):
                self.appState.bundleInfo = bundleInfo
                self.appState.newBundleName = bundleInfo.name
                self.loadImage()
            case .failure(let errorMessage):
                alertMessage = errorMessage
                showAlert = true
            }
        }
    }
}

#Preview {
    EditBundleView()
}
