import XCTest
@testable import BmadBrowser

final class ConfigResolverTests: XCTestCase {

    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("BmadBrowserTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    private func mkdir(_ name: String) throws {
        try FileManager.default.createDirectory(
            at: root.appendingPathComponent(name, isDirectory: true),
            withIntermediateDirectories: true
        )
    }

    func testLooksLikeBmadProjectDetectsMarkers() throws {
        XCTAssertFalse(ConfigResolver.looksLikeBmadProject(root))
        try mkdir("docs")
        XCTAssertTrue(ConfigResolver.looksLikeBmadProject(root))
    }

    func testResolveFallsBackToDocs() throws {
        try mkdir("docs")
        let out = ConfigResolver.resolveOutputFolder(projectRoot: root)
        XCTAssertEqual(out.lastPathComponent, "docs")
    }

    func testResolveReadsConfigAndExpandsProjectRoot() throws {
        try mkdir("_bmad")
        try mkdir("artifacts")
        let toml = "[core]\noutput_folder = \"{project-root}/artifacts\"\n"
        try toml.write(
            to: root.appendingPathComponent("_bmad/config.toml"),
            atomically: true, encoding: .utf8
        )
        let out = ConfigResolver.resolveOutputFolder(projectRoot: root)
        XCTAssertEqual(out.lastPathComponent, "artifacts")
    }

    func testResolveFallsBackToRootWhenNothing() {
        let out = ConfigResolver.resolveOutputFolder(projectRoot: root)
        XCTAssertEqual(out.standardizedFileURL, root.standardizedFileURL)
    }
}
