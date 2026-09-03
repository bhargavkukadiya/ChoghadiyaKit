//
//  ChoghadiyaTypeTests.swift
//  ChoghadiyaKitTests
//
//  Created by Bhargav Kukadiya.
//

import Testing
import Foundation
@testable import ChoghadiyaKit

@Suite("Choghadiya Type and Auspiciousness Tests")
struct ChoghadiyaTypeTests {

    @Test("Auspiciousness Categorization")
    func testAuspiciousness() {
        #expect(ChoghadiyaType.amrit.auspiciousness == .highlyAuspicious)
        #expect(ChoghadiyaType.amrit.isAuspicious == true)

        #expect(ChoghadiyaType.shubh.auspiciousness == .auspicious)
        #expect(ChoghadiyaType.shubh.isAuspicious == true)

        #expect(ChoghadiyaType.labh.auspiciousness == .auspicious)
        #expect(ChoghadiyaType.labh.isAuspicious == true)

        #expect(ChoghadiyaType.chal.auspiciousness == .neutral)
        #expect(ChoghadiyaType.chal.isAuspicious == false)

        #expect(ChoghadiyaType.udveg.auspiciousness == .inauspicious)
        #expect(ChoghadiyaType.udveg.isAuspicious == false)

        #expect(ChoghadiyaType.kaal.auspiciousness == .inauspicious)
        #expect(ChoghadiyaType.kaal.isAuspicious == false)

        #expect(ChoghadiyaType.rog.auspiciousness == .avoid)
        #expect(ChoghadiyaType.rog.isAuspicious == false)
    }

    @Test("Ruling Planets")
    func testRulingPlanets() {
        #expect(ChoghadiyaType.udveg.rulingPlanet.contains("Sun"))
        #expect(ChoghadiyaType.chal.rulingPlanet.contains("Venus"))
        #expect(ChoghadiyaType.labh.rulingPlanet.contains("Mercury"))
        #expect(ChoghadiyaType.amrit.rulingPlanet.contains("Moon"))
        #expect(ChoghadiyaType.kaal.rulingPlanet.contains("Saturn"))
        #expect(ChoghadiyaType.shubh.rulingPlanet.contains("Jupiter"))
        #expect(ChoghadiyaType.rog.rulingPlanet.contains("Mars"))
    }

    @Test("Legacy Label Backward Compatibility")
    func testLabels() {
        #expect(ChoghadiyaType.udveg.label == "Anxiety")
        #expect(ChoghadiyaType.chal.label == "Neutral")
        #expect(ChoghadiyaType.labh.label == "Beneficial")
        #expect(ChoghadiyaType.amrit.label == "Highly Auspicious")
        #expect(ChoghadiyaType.kaal.label == "Inauspicious")
        #expect(ChoghadiyaType.shubh.label == "Auspicious")
        #expect(ChoghadiyaType.rog.label == "Avoid")
    }

    @Test("CaseIterable Completeness")
    func testCases() {
        #expect(ChoghadiyaType.allCases.count == 7)
    }
}
