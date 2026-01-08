import XCTest
@testable import CoreDomain

final class CoreDomainTests: XCTestCase {
    func testPatientIDEquality() {
        let a = PatientID("123")
        let b = PatientID("123")
        XCTAssertEqual(a, b)
    }
}
