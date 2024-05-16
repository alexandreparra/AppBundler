//
//  CreateBundleTests.swift
//  AppBundlerTests
//
//  Created by Ale on 07/04/24.
//

import XCTest
@testable import AppBundler

final class CreateBundleTests: XCTestCase {

    func testCreateBundleOnTMPFolder_assertContentsWhereCreatedCorrectly() throws {
        let fileManager = FileManager.default
        let tempFolder = NSTemporaryDirectory()
        let tempFolderURL = URL(filePath: tempFolder)
        
        var binaryPath = tempFolderURL
        binaryPath.append(path: "testBinary")
        
        var iconPath = tempFolderURL
        iconPath.append(path: "testIcon.icns")
        
        fileManager.createFile(atPath: binaryPath.path(), contents: nil)
        fileManager.createFile(atPath: iconPath.path(), contents: nil)
        let bundleCreatedSuccessfully = createBundle(
            at: tempFolder,
            withName: "TestBundle",
            binaryPath: binaryPath.path(),
            iconLocation: iconPath.path()
        )
        XCTAssertEqual(bundleCreatedSuccessfully, true, "Couldn't create bundle at temporary directory")
        
        var testAppBundleURL = tempFolderURL
        testAppBundleURL.append(path: "TestBundle")
        let plist = Bundle(url: testAppBundleURL)?.infoDictionary
        XCTAssertNotNil(plist, "Couldn't find Info.plist at testAppBundle: \(testAppBundleURL.path())")
        
        try fileManager.removeItem(at: binaryPath)
        try fileManager.removeItem(at: iconPath)
        try fileManager.removeItem(at: tempFolderURL)
    }
}
