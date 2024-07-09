//
//  AppBundlerTests.swift
//  AppBundlerTests
//
//  Created by Ale on 28/03/24.
//

import XCTest
@testable import AppBundler

final class FindFileTests: XCTestCase {
    
    func testFindFileWithoutExtension_folderContainsIconNameWithoutExtension() throws {
        let iconName = "AppIcon"
        let folderContents = ["build.txt", "product-info.json", "shaders", iconName]
        let foundIconName = findFileInside(folderContents: folderContents, iconName: iconName)
        XCTAssertEqual(
            foundIconName,
            iconName,
            "File AppIcon wans't found on folderContents that listed it"
        )
    }

    func testFindFileWithoutExtension_folderContainsIconNameHasExtension() throws {
        let iconName = "AppIcon"
        let expectedFoundName = "AppIcon.icns"
        let folderContents = ["build.txt", "product-info.json", "shaders", expectedFoundName]
        let foundIconName = findFileInside(folderContents: folderContents, iconName: iconName)
        XCTAssertEqual(
            foundIconName,
            expectedFoundName,
            "Provided name AppIcon wasn't found inside folderContents correctly considering an aditional file extension"
        )
    }
    
    func testFindFileWithExtension_folderContainsIconNameWithExtension() throws {
        let iconName = "AppIcon.icns"
        let folderContents = ["build.txt", "product-info.json", "shaders", iconName]
        let foundIconName = findFileInside(folderContents: folderContents, iconName: iconName)
        XCTAssertEqual(foundIconName, iconName, "File AppIcon.icns wans't found on folderContents that listed it")
    }
    
}
