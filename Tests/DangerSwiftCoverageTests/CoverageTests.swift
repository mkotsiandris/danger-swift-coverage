@testable import Danger
import DangerFixtures
@testable import DangerSwiftCoverage
import XCTest

final class CoverageTests: XCTestCase {
    var dsl: DangerDSL!

    override func setUp() {
        super.setUp()
        MockXcodeBuildCoverageParser.receivedDataFolder = nil
        MockXcodeBuildCoverageParser.receivedFiles = nil
        MockXcodeBuildCoverageParser.receivedExcludedTargets = nil
        MockXcodeBuildCoverageParser.shouldSucceed = false
    }

    override func tearDown() {
        dsl = nil
        resetDangerResults()

        super.tearDown()
    }

    func testItSendsAFailMessageIfFailsToParseTheXcodeBuildCoverage() {
        dsl = githubFixtureDSL
        Coverage.xcodeBuildCoverage(derivedDataFolder: "derived", minimumCoverage: 50, excludedTargets: [], fileManager: FakeCurrentPathProvider(), xcodeBuildCoverageParser: MockXcodeBuildCoverageParser.self, danger: dsl)

        XCTAssertEqual(dsl.fails.count, 1)
        XCTAssertEqual(dsl.fails[0].message, "Failed to get the coverage - Error: Fake Error")
    }

    func testItSendsTheCorrectParametersToTheXcodeBuildCoverageParser() {
        let created = [
            ".travis.yml",
            "Tests/Test.swift",
        ]

        let modified = [
            "Sources/Coverage.swift",
        ]

        dsl = githubWithFilesDSL(created: created, modified: modified)

        let currentPathProvider = FakeCurrentPathProvider()
        let excluedTargets = ["TargetA.framework", "TargetB.framework"]

        Coverage.xcodeBuildCoverage(derivedDataFolder: "derived", minimumCoverage: 50, excludedTargets: excluedTargets, fileManager: currentPathProvider, xcodeBuildCoverageParser: MockXcodeBuildCoverageParser.self, danger: dsl)

        XCTAssertEqual(MockXcodeBuildCoverageParser.receivedDataFolder, "derived")
        XCTAssertEqual(MockXcodeBuildCoverageParser.receivedExcludedTargets, excluedTargets)
        XCTAssertEqual(MockXcodeBuildCoverageParser.receivedFiles, (created + modified).map { currentPathProvider.fakePath + "/" + $0 })
    }

    func testItSendsTheCorrectRepoToDanger() {
        dsl = githubWithFilesDSL()
        MockXcodeBuildCoverageParser.shouldSucceed = true

        Coverage.xcodeBuildCoverage(derivedDataFolder: "derived", minimumCoverage: 50, excludedTargets: [], fileManager: FakeCurrentPathProvider(), xcodeBuildCoverageParser: MockXcodeBuildCoverageParser.self, danger: dsl)

        XCTAssertEqual(dsl.messages.map { $0.message }, ["TestMessage1", "TestMessage2"])

        XCTAssertEqual(dsl.markdowns.map { $0.message }, [
            """
            ## Danger.framework: Coverage: 43.44%
            | File | Coverage ||
            | --- | --- | --- |
            BitBucketServerDSL.swift | 100.0% | ✅
            Danger.swift | 0.0% | ❌\n
            """,
            """
            ## RunnerLib.framework: Coverage: 66.67%
            | File | Coverage ||
            | --- | --- | --- |
            ImportsFinder.swift | 100.0% | ✅
            HelpMessagePresenter.swift | 100.0% | ✅\n
            """,
        ])
    }
}

fileprivate final class MockXcodeBuildCoverageParser: XcodeBuildCoverageParsing {
    static var receivedFiles: [String]!
    static var receivedDataFolder: String!
    static var receivedExcludedTargets: [String]!

    static var shouldSucceed = false

    enum FakeError: LocalizedError {
        case fakeError

        var errorDescription: String? {
            return "Fake Error"
        }
    }

    static let fakeReport = Report(messages: ["TestMessage1", "TestMessage2"],
                                   sections:
                                   [
                                       ReportSection(titleText: "Danger.framework: Coverage: 43.44%", items: [
                                           ReportFile(fileName: "BitBucketServerDSL.swift", coverage: 100),
                                           ReportFile(fileName: "Danger.swift", coverage: 0),
                                       ]),
                                       ReportSection(titleText: "RunnerLib.framework: Coverage: 66.67%", items: [
                                           ReportFile(fileName: "ImportsFinder.swift", coverage: 100),
                                           ReportFile(fileName: "HelpMessagePresenter.swift", coverage: 100),
                                       ]),
    ])

    static func coverage(derivedDataFolder: String, files: [String], excludedTargets: [String]) throws -> Report {
        receivedFiles = files
        receivedDataFolder = derivedDataFolder
        receivedExcludedTargets = excludedTargets

        if shouldSucceed {
            return fakeReport
        } else {
            throw FakeError.fakeError
        }
    }
}
