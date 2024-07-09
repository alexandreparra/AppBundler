import SwiftUI

struct CreateBundleView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Form {
            HStack {
                Text("Name:")
                TextField(text: $appState.bundleName) {}
            }
            
            HStack {
                Text("Binary Path:")
                TextField(text: $appState.binaryPath) {}
                Button("Choose") {
                    appState.binaryPath = chooseFile()
                }
            }
            
            HStack {
                Text("Icon Path:")
                TextField(text: $appState.iconPath) {}
                Button("Choose") {
                    appState.iconPath = chooseIcon()
                }
            }
            
            HStack {
                Button("Create Bundle", action: clickCreateBundle)
            }.frame(maxWidth: .infinity, alignment: .trailing)
        }.padding()
    }
    
    func clickCreateBundle() {
        if appState.bundleName.isEmpty || appState.binaryPath.isEmpty {
           return
        }
        
        let bundleSavePath = chooseSaveFolder()
        if bundleSavePath != "" {
            let succeed = createNSBundle(
                at: bundleSavePath,
                withName: appState.bundleName,
                binaryPath: appState.binaryPath,
                iconLocation: appState.iconPath
            )
            
            if succeed {
                appState.bundleName = ""
                appState.binaryPath = ""
                appState.iconPath = ""
            }
        }
    }
}

#Preview {
    CreateBundleView()
}
