import Foundation
import SwiftData

@Model
final class PatientRecord {
    @Attribute(.unique) var id: String
    var given: String
    var family: String
    var mrn: String?
    var gender: String
    var birthDate: Date?
    var providerName: String?

    init(id: String, given: String, family: String, mrn: String?, gender: String, birthDate: Date?, providerName: String?) {
        self.id = id
        self.given = given
        self.family = family
        self.mrn = mrn
        self.gender = gender
        self.birthDate = birthDate
        self.providerName = providerName
    }
}

@Model
final class EncounterRecord {
    @Attribute(.unique) var id: String
    var patientID: String
    var classCode: String
    var start: Date?
    var end: Date?
    var locationName: String?

    init(id: String, patientID: String, classCode: String, start: Date?, end: Date?, locationName: String?) {
        self.id = id
        self.patientID = patientID
        self.classCode = classCode
        self.start = start
        self.end = end
        self.locationName = locationName
    }
}

@Model
final class ObservationRecord {
    @Attribute(.unique) var id: String
    var patientID: String
    var codeSystem: String
    var code: String
    var display: String?
    var effectiveDate: Date?
    var valueDescription: String

    init(
        id: String,
        patientID: String,
        codeSystem: String,
        code: String,
        display: String?,
        effectiveDate: Date?,
        valueDescription: String
    ) {
        self.id = id
        self.patientID = patientID
        self.codeSystem = codeSystem
        self.code = code
        self.display = display
        self.effectiveDate = effectiveDate
        self.valueDescription = valueDescription
    }
}

struct SwiftDataModelSchema {
    static let schema = Schema([
        PatientRecord.self,
        EncounterRecord.self,
        ObservationRecord.self
    ])
}
