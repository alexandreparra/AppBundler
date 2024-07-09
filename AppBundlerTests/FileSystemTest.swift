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
    
    func testDetermineBinaryType_executableShouldBeProperlyRecognized() throws {
        let binaryName = "AppBundler"
        let result = determineBinaryType(binaryName: binaryName)
        XCTAssertEqual(
            BinaryType.exec,
            result,
            "Pure executable binary wasn't properly recognized"
        )
    }
    
    func testDetermineBinaryType_jarShouldBeProperlyRecognized() throws {
        let binaryName = "minecraft.jar"
        let result = determineBinaryType(binaryName: binaryName)
        XCTAssertEqual(
            BinaryType.jar,
            result,
            "Jar wasn't properly recognized"
        )
    }
}
