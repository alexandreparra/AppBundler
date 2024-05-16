//
//  AppBundlerApp.swift
//  AppBundler
//  Created on 17/03/24.
//

import SwiftUI

enum ScreenType {
    case createBundle, editBundle
}

struct Screen: Identifiable {
    let name: String
    let type: ScreenType
    let id = UUID()
}

class AppState: ObservableObject {
    // CreateBundleView
    @Published var bundleName = ""
    @Published var binaryPath = ""
    @Published var iconPath = ""
    
    // InspectBundleView
    @Published var bundlePath = ""
    @Published var bundleInfo = BundleInfo(path: "", name: "", iconPath: "")
    @Published var image = Image(systemName: "exclamationmark.square.fill")
}

@main
struct AppBundlerApp: App {
    @StateObject private var appState = AppState()
    
    @State private var screens = [
        Screen(name: "Create Bundle", type: .createBundle),
        Screen(name: "Edit Bundle", type: .editBundle)
    ]
    
    @State private var chosenScreen = ScreenType.createBundle
    
    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                List(selection: $chosenScreen) {
                    ForEach(screens, id: \.type) { screen in
                        NavigationLink(value: screen.name) {
                            Text(screen.name)
                        }
                    }
                }
            } detail: {
                switch chosenScreen {
                case .createBundle:
                    CreateBundleView()
                        .environmentObject(appState)
                case .editBundle:
                    EditBundleView()
                        .environmentObject(appState)
                }
            }
            .frame(minWidth: 600, maxWidth: 600, minHeight: 200, maxHeight: 200)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Create Bundle") {
                    chosenScreen = .createBundle
                }
                Button("Edit Bundle") {
                    chosenScreen = .editBundle
                }
            }
        }
    }
}
