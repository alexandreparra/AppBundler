//
//  CreateBundleView.swift
//  AppBundler
//  Created on 17/03/24.
//

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
                    appState.binaryPath = findIconPath()
                }
            }
            
            HStack {
                Text("Icon Path:")
                TextField(text: $appState.iconPath) {}
                Button("Choose") {
                    appState.iconPath = findIconPath()
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
        
        let bundleSavePath = chooseFolder()
        if bundleSavePath != "" {
            let success = createBundle(
                at: bundleSavePath,
                withName: appState.bundleName,
                binaryPath: appState.binaryPath,
                iconLocation: appState.iconPath
            )
            
            if success {
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
