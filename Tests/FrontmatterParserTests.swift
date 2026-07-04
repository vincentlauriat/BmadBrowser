import XCTest
@testable import BmadBrowser

final class FrontmatterParserTests: XCTestCase {

    // MARK: - Round-trip fidèle (le fix de non-corruption)

    /// Réécrire `rawBlock + "\n" + body` doit reproduire l'original à l'octet près,
    /// y compris l'ordre des clés et les listes YAML.
    func testRoundTripPreservesOrderAndLists() {
        let original = """
        ---
        status: complete
        workflowType: prd
        inputDocuments:
          - brief.md
          - research.md
        date: 2026-07-04
        ---
        # Title

        Body text.
        """
        let (fm, body) = FrontmatterParser.parse(original)
        XCTAssertNotNil(fm.rawBlock)
        let rebuilt = fm.rawBlock! + "\n" + body
        XCTAssertEqual(rebuilt, original, "Le round-trip doit préserver l'original exactement")
    }

    func testParsedScalarProperties() {
        let text = """
        ---
        status: in-progress
        workflowType: architecture
        completedAt: 2026-01-02
        ---
        body
        """
        let (fm, body) = FrontmatterParser.parse(text)
        XCTAssertEqual(fm.status, "in-progress")
        XCTAssertEqual(fm.workflowType, "architecture")
        XCTAssertEqual(fm.date, "2026-01-02")
        XCTAssertEqual(body, "body")
    }

    func testNoFrontmatterReturnsWholeBody() {
        let text = "# No frontmatter\n\nJust content."
        let (fm, body) = FrontmatterParser.parse(text)
        XCTAssertTrue(fm.isEmpty)
        XCTAssertNil(fm.rawBlock)
        XCTAssertEqual(body, text)
    }

    // MARK: - Champs scalaires éditables

    func testScalarFieldsIgnoresListsAndKeepsScalars() {
        let raw = """
        ---
        status: draft
        inputDocuments:
          - a.md
        date: 2026-07-04
        ---
        """
        let fields = FrontmatterParser.scalarFields(from: raw)
        let keys = fields.map(\.key)
        XCTAssertEqual(keys, ["status", "date"], "inputDocuments (liste) ne doit pas être un champ scalaire")
    }

    func testApplyingRewritesOnlyEditedLinesAndPreservesLists() {
        let raw = """
        ---
        status: draft
        inputDocuments:
          - a.md
        ---
        """
        var fields = FrontmatterParser.scalarFields(from: raw)
        fields[0].value = "complete"
        let updated = FrontmatterParser.applying(fields, to: raw)
        XCTAssertTrue(updated.contains("status: complete"))
        XCTAssertTrue(updated.contains("  - a.md"), "La ligne de liste doit rester intacte")
        XCTAssertFalse(updated.contains("status: draft"))
    }
}
