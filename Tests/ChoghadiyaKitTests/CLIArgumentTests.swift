import XCTest
@testable import ChoghadiyaDemo

final class CLIArgumentTests: XCTestCase {
    // MARK: - Tests

    func testRejectsUnknownDuplicateAndUnusedArguments() {
        let invalidInputs = [
            ["--lat", "23", "--lon", "72", "--dat", "2026-10-24"],
            ["--lat", "23", "--lon", "72", "extra"],
            ["--lat", "23"],
            ["--lon", "72"],
            ["--lat", "23", "--lon"],
            ["--lat", "23", "--lon", "72", "--lat", "24"],
            ["23", "72", "Asia/Kolkata", "extra"],
            ["23", "72", "Asia/Kolkata", "--tz", "UTC"],
            ["23", "72", "--date", "2026-10-24", "--date", "2026-10-25"],
            ["23", "72", "--tz", "UTC", "--tz", "UTC"],
            ["23,72", "extra"],
            ["23,72", "Asia/Kolkata", "extra"],
            ["23,72", "Asia/Kolkata", "--tz", "UTC"],
            ["23,72", "Invalid/Timezone"],
            ["London", "--tz", "UTC"],
            ["--tz", "UTC"]
        ]
        for arguments in invalidInputs {
            XCTAssertThrowsError(try ChoghadiyaDemo.parseArguments(arguments), "\(arguments)")
        }
    }

    func testValidCoordinateFormsPreserveDateAndTimeZone() throws {
        let inputs = [
            ["--lat", "-23", "--lon", "-72", "--tz", "UTC"],
            ["-23", "-72", "UTC"],
            ["-23,-72", "--tz", "UTC"],
            ["-23,-72", "UTC"]
        ]
        for arguments in inputs {
            let input = try ChoghadiyaDemo.parseArguments(arguments + ["--date", "2026-10-24"])
            guard case .coordinates(let latitude, let longitude, let zone, let date) = input else {
                return XCTFail("Expected coordinate input")
            }
            XCTAssertEqual(latitude, -23)
            XCTAssertEqual(longitude, -72)
            XCTAssertEqual(zone.secondsFromGMT(), 0)
            XCTAssertEqual(date?.year, 2026)
            XCTAssertEqual(date?.month, 10)
            XCTAssertEqual(date?.day, 24)
        }
    }

    func testAddressAndDefaultModes() throws {
        for arguments in [[], ["London", "UK"]] {
            guard case .address(let address, _) = try ChoghadiyaDemo.parseArguments(arguments) else {
                return XCTFail("Expected address input")
            }
            XCTAssertEqual(address, arguments.isEmpty ? "Ahmedabad, India" : "London UK")
        }
    }
}
