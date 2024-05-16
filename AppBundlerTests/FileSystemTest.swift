//
//  FileSystemTest.swift
//  AppBundlerTests
//
//  Created by Ale on 04/05/24.
//

import XCTest
@testable import AppBundler

final class FileSystemTest: XCTestCase {

    func testRenameFile_fileShouldMaintainFileExtension() throws {
        let fileURL = URL(filePath: "/Users/mock/file_test.mock")
        let newFileName = "test_success"
        let expectedFileNameWithExtension = "\(newFileName).mock"
        let result = renameFile(at: fileURL, newName: newFileName)
        XCTAssertEqual(
            expectedFileNameWithExtension,
            result,
            "File named file_test.mock wasn't rename correctly to test_success.mock"
        )
    }
}
