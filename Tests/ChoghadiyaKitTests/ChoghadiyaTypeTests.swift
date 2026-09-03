//
//  ChoghadiyaTypeTests.swift
//  ChoghadiyaKitTests
//
//  Created by Bhargav Kukadiya.
//

import XCTest
@testable import ChoghadiyaKit

final class ChoghadiyaTypeTests: XCTestCase {

    func testAuspiciousness() {
        XCTAssertEqual(ChoghadiyaType.amrit.auspiciousness, .highlyAuspicious)
        XCTAssertTrue(ChoghadiyaType.amrit.isAuspicious)

        XCTAssertEqual(ChoghadiyaType.shubh.auspiciousness, .auspicious)
        XCTAssertTrue(ChoghadiyaType.shubh.isAuspicious)

        XCTAssertEqual(ChoghadiyaType.labh.auspiciousness, .auspicious)
        XCTAssertTrue(ChoghadiyaType.labh.isAuspicious)

        XCTAssertEqual(ChoghadiyaType.chal.auspiciousness, .neutral)
        XCTAssertFalse(ChoghadiyaType.chal.isAuspicious)

        XCTAssertEqual(ChoghadiyaType.udveg.auspiciousness, .inauspicious)
        XCTAssertFalse(ChoghadiyaType.udveg.isAuspicious)

        XCTAssertEqual(ChoghadiyaType.kaal.auspiciousness, .inauspicious)
        XCTAssertFalse(ChoghadiyaType.kaal.isAuspicious)

        XCTAssertEqual(ChoghadiyaType.rog.auspiciousness, .avoid)
        XCTAssertFalse(ChoghadiyaType.rog.isAuspicious)
    }

    func testRulingPlanets() {
        XCTAssertTrue(ChoghadiyaType.udveg.rulingPlanet.contains("Sun"))
        XCTAssertTrue(ChoghadiyaType.chal.rulingPlanet.contains("Venus"))
        XCTAssertTrue(ChoghadiyaType.labh.rulingPlanet.contains("Mercury"))
        XCTAssertTrue(ChoghadiyaType.amrit.rulingPlanet.contains("Moon"))
        XCTAssertTrue(ChoghadiyaType.kaal.rulingPlanet.contains("Saturn"))
        XCTAssertTrue(ChoghadiyaType.shubh.rulingPlanet.contains("Jupiter"))
        XCTAssertTrue(ChoghadiyaType.rog.rulingPlanet.contains("Mars"))
    }

    func testLabels() {
        XCTAssertEqual(ChoghadiyaType.udveg.label, "Anxiety")
        XCTAssertEqual(ChoghadiyaType.chal.label, "Neutral")
        XCTAssertEqual(ChoghadiyaType.labh.label, "Beneficial")
        XCTAssertEqual(ChoghadiyaType.amrit.label, "Highly Auspicious")
        XCTAssertEqual(ChoghadiyaType.kaal.label, "Inauspicious")
        XCTAssertEqual(ChoghadiyaType.shubh.label, "Auspicious")
        XCTAssertEqual(ChoghadiyaType.rog.label, "Avoid")
    }

    func testCases() {
        XCTAssertEqual(ChoghadiyaType.allCases.count, 7)
    }
}
