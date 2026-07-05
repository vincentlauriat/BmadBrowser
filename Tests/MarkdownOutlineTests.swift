import XCTest
@testable import BmadBrowser

final class MarkdownOutlineTests: XCTestCase {

    func testExtractsHeadingsWithLevels() {
        let body = """
        # Title
        intro
        ## Section A
        text
        ### Sub A1
        """
        let headings = MarkdownOutline.split(body).headings
        XCTAssertEqual(headings.map(\.title), ["Title", "Section A", "Sub A1"])
        XCTAssertEqual(headings.map(\.level), [1, 2, 3])
    }

    func testIgnoresHeadingsInsideCodeFence() {
        let body = """
        # Real
        ```
        # not a heading
        ```
        ## Also real
        """
        let headings = MarkdownOutline.split(body).headings
        XCTAssertEqual(headings.map(\.title), ["Real", "Also real"])
    }

    func testPreambleBecomesItsOwnSection() {
        let body = """
        some intro text
        # First
        body
        """
        let (sections, headings) = MarkdownOutline.split(body)
        XCTAssertEqual(sections.count, 2, "préambule + section du titre")
        XCTAssertEqual(headings.count, 1)
        XCTAssertEqual(headings.first?.id, "section-1", "le titre pointe la 2e section")
    }

    func testRequiresSpaceAfterHashes() {
        let body = "#nospace\n# yes"
        let headings = MarkdownOutline.split(body).headings
        XCTAssertEqual(headings.map(\.title), ["yes"])
    }

    func testRoundTripPreservesBody() {
        let body = "# A\nx\n## B\ny"
        let sections = MarkdownOutline.split(body).sections
        XCTAssertEqual(sections.map(\.text).joined(separator: "\n"), body)
    }
}
