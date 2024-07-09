import XCTest
@testable import AppBundler

final class StringExtensionTest: XCTestCase {

    func testStringRemovePathExtension_filesShould() throws {
        let jar = "java.jar"
        XCTAssertEqual("java", jar.removePathExtension(), ".jar extension wasn't removed")
        
        let app = "appbundler.app"
        XCTAssertEqual("appbundler", app.removePathExtension(), ".app extension wasn't removed")
    }
}
