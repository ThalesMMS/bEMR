import XCTest
@testable import CoreUseCases
@testable import CoreDomain

final class CoreUseCasesTests: XCTestCase {
    func testLoadPatientListDelegatesToRepository() async throws {
        let repo = PatientRepositorySpy()
        let sut = LoadPatientListUseCase(patientRepo: repo, pageSize: 10)

        _ = try await sut.execute(query: "smith", page: 1)

        XCTAssertEqual(repo.receivedQuery, "smith")
        XCTAssertEqual(repo.receivedPage, 1)
    }
}

private final class PatientRepositorySpy: PatientRepository {
    var receivedQuery: String?
    var receivedPage: Int?
    var receivedPageSize: Int?

    func searchPatients(query: String?, page: Int, pageSize: Int) async throws -> [Patient] {
        receivedQuery = query
        receivedPage = page
        receivedPageSize = pageSize
        return []
    }

    func patient(by id: PatientID) async throws -> Patient? {
        nil
    }
}
