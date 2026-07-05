import XCTest
@testable import BmadBrowser

final class SemVerTests: XCTestCase {

    func testNewerDetectsHigherVersions() {
        XCTAssertTrue(SemVer.isNewer("1.1.0", than: "1.0.0"))
        XCTAssertTrue(SemVer.isNewer("1.0.1", than: "1.0.0"))
        XCTAssertTrue(SemVer.isNewer("2.0.0", than: "1.9.9"))
    }

    func testNotNewerForEqualOrOlder() {
        XCTAssertFalse(SemVer.isNewer("1.0.0", than: "1.0.0"))
        XCTAssertFalse(SemVer.isNewer("1.0.0", than: "1.1.0"))
        XCTAssertFalse(SemVer.isNewer("1.0.0", than: "1.0.1"))
    }

    func testIgnoresLeadingVAndSuffixes() {
        XCTAssertTrue(SemVer.isNewer("v1.2.0", than: "1.1.0"))
        XCTAssertEqual(SemVer.compare("1.2.0-beta", "1.2.0"), .orderedSame)
    }

    func testDifferentComponentCounts() {
        XCTAssertEqual(SemVer.compare("1.2", "1.2.0"), .orderedSame)
        XCTAssertTrue(SemVer.isNewer("1.2.1", than: "1.2"))
    }
}
