Below is a full architecture blueprint you can implement in Swift for a FHIR/HL7/HIPAA‑aligned EMR with:

*   macOS (AppKit)
    
*   iOS + iPadOS (mobile & tablet)
    
*   watchOS (lightweight companion for patient list + notifications)
    
*   Clean architecture enforced via modularization and dependency inversion.
    

I’ll assume FHIR R4, SMART on FHIR for auth, and that your system is a FHIR client to an enterprise FHIR server (Epic, Cerner, custom HAPI‑FHIR, Azure API for FHIR, etc.). [build.fhir.org+2hl7.org+2](https://build.fhir.org/encounter.html?utm_source=chatgpt.com)

* * *

## 1\. High‑Level System View

**On the server side (not Swift, but required for design):**

1.  **FHIR API**
    
    *   Standards‑compliant FHIR R4 endpoint, SMART on FHIR capable.[SMART on FHIR+1](https://docs.smarthealthit.org/?utm_source=chatgpt.com)
        
    *   Exposes core resources: `Patient`, `Encounter`, `Observation`, `Condition`, `MedicationRequest`, `Procedure`, `AllergyIntolerance`, `DocumentReference`, etc.
        
2.  **HL7 Integration Layer**
    
    *   Bridges legacy HL7 v2/v3 (ADT, ORU, ORM) to FHIR resources.
        
    *   Typically a separate integration engine (Rhapsody, Mirth, Cloverleaf) that maps HL7 messages into FHIR resources; the Swift apps only talk FHIR.
        
3.  **Auth & Identity**
    
    *   OAuth2/OpenID Connect (SMART on FHIR style) for clinicians; tokens provided to the client apps.
        
4.  **Audit / Logging / IAM / SIEM**
    
    *   All access and changes to PHI logged centrally for HIPAA auditing.
        

**On the client side (Swift, all platforms):**

*   All Apple apps share:
    
    *   A **Domain layer** (business entities/use cases).
        
    *   A **Data layer** (FHIR client, repositories, persistence).
        
    *   **Security utilities** (Keychain, crypto, secure storage).
        
*   Platform‑specific layers implement UI and OS‑specific concerns.
    

* * *

## 2\. Clean Architecture Layers & Modules

Use Swift Package Manager and Xcode multi‑target project:

### 2.1 Module layout

*   `CoreDomain` (SPM package)
    
*   `CoreUseCases` (SPM package)
    
*   `FHIRModelsKit` (SPM, wrapper for 3rd‑party FHIR models)
    
*   `DataFHIR` (SPM)
    
*   `DataLocal` (SPM)
    
*   `SecurityKit` (SPM)
    
*   `SharedPresentation` (SPM; view models + common presentation logic)
    
*   App targets:
    
    *   `EMRMac` (AppKit)
        
    *   `EMRiOS` (SwiftUI/UIKit host)
        
    *   `EMRiPadOS` (same as iOS, different scenes)
        
    *   `EMRWatch` (watchOS SwiftUI)
        

Dependencies (outer → inner):

*   Apps → `SharedPresentation`
    
*   `SharedPresentation` → `CoreUseCases` → `CoreDomain`
    
*   `CoreUseCases` → repository protocols (in `CoreDomain`)
    
*   Infrastructure modules (`DataFHIR`, `DataLocal`) implement those protocols and depend on:
    
    *   `FHIRModelsKit`
        
    *   `SecurityKit`
        
    *   OS frameworks (URLSession, Core Data, etc.)
        

No platform framework should ever leak into `CoreDomain` / `CoreUseCases`.

* * *

## 3\. Domain Layer (CoreDomain)

### 3.1 Domain models

Domain entities are business‑friendly abstractions over FHIR resources (not 1:1 models). FHIR stays in the data layer, domain works with “pure Swift” structs and enums.

`// CoreDomain  struct PatientID: Hashable {     let rawValue: String }  struct Patient {     let id: PatientID     var mrn: String?     var name: PersonName     var birthDate: Date?     var gender: AdministrativeGender     var primaryProvider: ClinicianSummary?     var identifiers: [Identifier] }  struct PersonName {     var given: String     var family: String     var prefix: String?     var suffix: String? }  enum AdministrativeGender {     case male, female, other, unknown }  struct Encounter {     let id: String     let patientID: PatientID     let classCode: EncounterClass     let start: Date?     let end: Date?     let locationName: String? }  enum EncounterClass {     case inpatient, outpatient, emergency, homeHealth, virtual, unknown }  struct Observation {     let id: String     let patientID: PatientID     let code: Code     let effectiveDate: Date?     let value: ObservationValue }  enum ObservationValue {     case quantity(value: Double, unit: String)     case code(Code)     case string(String)     case boolean(Bool) }  struct Code {     let system: String     let code: String     let display: String? }`

### 3.2 Repository protocols

These are implemented by the Data layer:

`// CoreDomain  protocol PatientRepository {     func searchPatients(query: String?, page: Int, pageSize: Int) async throws -> [Patient]     func patient(by id: PatientID) async throws -> Patient? }  protocol EncounterRepository {     func encounters(for patientID: PatientID) async throws -> [Encounter] }  protocol ObservationRepository {     func recentVitals(for patientID: PatientID, limit: Int) async throws -> [Observation] }  protocol AuthRepository {     func currentUser() async throws -> Clinician     func refreshTokenIfNeeded() async throws }`

* * *

## 4\. Use Case Layer (CoreUseCases)

Each use case is an interactor/service that orchestrates repositories and domain logic. It knows nothing about networking or UI.

`// CoreUseCases  public struct LoadPatientListUseCase {     private let patientRepo: PatientRepository          public init(patientRepo: PatientRepository) {         self.patientRepo = patientRepo     }          public func execute(query: String?, page: Int) async throws -> [Patient] {         try await patientRepo.searchPatients(query: query, page: page, pageSize: 50)     } }  public struct LoadPatientSummaryUseCase {     private let patientRepo: PatientRepository     private let encounterRepo: EncounterRepository     private let observationRepo: ObservationRepository          public init(patientRepo: PatientRepository,                 encounterRepo: EncounterRepository,                 observationRepo: ObservationRepository) {         self.patientRepo = patientRepo         self.encounterRepo = encounterRepo         self.observationRepo = observationRepo     }          public func execute(patientID: PatientID) async throws -> PatientSummary {         async let patient = patientRepo.patient(by: patientID)         async let encounters = encounterRepo.encounters(for: patientID)         async let vitals = observationRepo.recentVitals(for: patientID, limit: 10)                  guard let p = try await patient else {             throw DomainError.patientNotFound         }                  return PatientSummary(patient: p,                               recentEncounters: try await encounters,                               recentVitals: try await vitals)     } }`

This layer is where business rules (e.g., what counts as “recent encounters”) live.

* * *

## 5\. FHIR Models & Client (FHIRModelsKit + DataFHIR)

### 5.1 FHIR models

Use Apple’s `FHIRModels` or SMART’s `Swift-FHIR` for native Swift FHIR types. [GitHub+2GitHub+2](https://github.com/apple/FHIRModels?utm_source=chatgpt.com)

Create a wrapper module (`FHIRModelsKit`) that re‑exports the specific FHIR version (R4):

`// Package.swift (excerpt) .package(url: "https://github.com/apple/FHIRModels.git", from: "0.7.0"),  // FHIRModelsKit module: @_exported import FHIRModelsR4`

### 5.2 FHIR HTTP client

`DataFHIR` implements repositories using URLSession with Swift Concurrency and SMART on FHIR for auth. [SMART on FHIR+1](https://docs.smarthealthit.org/?utm_source=chatgpt.com)

`// DataFHIR  final class FHIRClient {     private let baseURL: URL     private let authRepository: AuthRepository          init(baseURL: URL, authRepository: AuthRepository) {         self.baseURL = baseURL         self.authRepository = authRepository     }          func get<Resource: Codable>(_ path: String,                                 queryItems: [URLQueryItem] = []) async throws -> Resource {         try await authRepository.refreshTokenIfNeeded()         let token = try await fetchAccessToken()                  var components = URLComponents(url: baseURL.appendingPathComponent(path),                                        resolvingAgainstBaseURL: false)!         components.queryItems = queryItems                  var request = URLRequest(url: components.url!)         request.httpMethod = "GET"         request.addValue("application/fhir+json", forHTTPHeaderField: "Accept")         request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")                  let (data, response) = try await URLSession.shared.data(for: request)         guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {             throw FHIRClientError.httpError         }                  return try JSONDecoder().decode(Resource.self, from: data)     }          // Access token retrieval from Keychain/secure store     private func fetchAccessToken() async throws -> String {         // ...     } }`

### 5.3 Repository implementation example

`// DataFHIR  final class FHIRPatientRepository: PatientRepository {     private let client: FHIRClient          init(client: FHIRClient) {         self.client = client     }          func searchPatients(query: String?, page: Int, pageSize: Int) async throws -> [Patient] {         var queryItems: [URLQueryItem] = [             .init(name: "_count", value: "\(pageSize)"),             .init(name: "_offset", value: "\(page * pageSize)")         ]         if let q = query, !q.isEmpty {             queryItems.append(.init(name: "name", value: q))         }                  let bundle: Bundle = try await client.get("Patient", queryItems: queryItems)         let entries = bundle.entry ?? []                  return entries.compactMap { entry in             guard let fhirPatient = entry.resource?.get(if: Patient.self) else { return nil }             return PatientMapper.fromFHIR(fhirPatient)         }     } }`

`PatientMapper` lives in `DataFHIR` and converts between FHIR and domain types (e.g., mapping FHIR Encounter class codes to `EncounterClass`). [terminology.hl7.org+1](https://terminology.hl7.org/5.1.0/ValueSet-encounter-class.html?utm_source=chatgpt.com)

* * *

## 6\. Local Persistence (DataLocal)

Aim for **minimal PHI at rest** on device; only what is needed for workflow, all encrypted.

*   Use **Core Data** or **SQLite** with:
    
    *   iOS/iPadOS: `NSPersistentStoreFileProtectionKey` set to `.complete` or `.completeUnlessOpen`.
        
    *   macOS: rely on FileVault + app‑level encryption of the DB file.
        
*   Never sync PHI via iCloud / CloudKit, as Apple does not sign HIPAA BAAs for iCloud; you cannot rely on it for PHI. [The HIPAA Journal+2HIPAA Times+2](https://www.hipaajournal.com/icloud-hipaa-compliant/?utm_source=chatgpt.com)
    

`DataLocal` implements caching repositories that decorate FHIR repositories:

`final class CachingPatientRepository: PatientRepository {     private let remote: PatientRepository     private let localStore: PatientLocalStore          init(remote: PatientRepository, localStore: PatientLocalStore) {         self.remote = remote         self.localStore = localStore     }          func searchPatients(query: String?, page: Int, pageSize: Int) async throws -> [Patient] {         let remotePatients = try await remote.searchPatients(query: query, page: page, pageSize: pageSize)         try await localStore.save(patients: remotePatients)         return remotePatients     }          func patient(by id: PatientID) async throws -> Patient? {         if let cached = try await localStore.patient(by: id) {             return cached         }         let remote = try await remote.patient(by: id)         if let p = remote {             try await localStore.save(patients: [p])         }         return remote     } }`

* * *

## 7\. Security & HIPAA Alignment

This is not legal advice, but these are common technical patterns aligned with HIPAA Security Rule guidance. [nordlayer.com+3HHS+3The HIPAA Journal+3](https://www.hhs.gov/hipaa/for-professionals/security/laws-regulations/index.html?utm_source=chatgpt.com)

### 7.1 Data in transit

*   All FHIR and auth endpoints: **TLS 1.2 or 1.3**, strong ciphers (AES‑128/256, PFS).[censinet.com+1](https://censinet.com/perspectives/hipaa-encryption-rules-for-data-in-transit?utm_source=chatgpt.com)
    
*   Validate certificates and use ATS (App Transport Security).
    

### 7.2 Data at rest

*   Encrypt all PHI on device:
    
    *   Leverage OS‑level full‑disk encryption (iOS automatic, FileVault on macOS).
        
    *   Additionally, encrypt sensitive DB fields with AES‑256 using a key stored in Keychain / Secure Enclave.
        
*   Ensure logging frameworks never log PHI.
    

### 7.3 Authentication & authorization

*   SMART on FHIR/OAuth2:
    
    *   Authorization code flow with PKCE where applicable.
        
    *   Store tokens in Keychain; never in UserDefaults.
        
*   Enforce App‑side session timeout and re‑auth for critical operations.
    

### 7.4 Push notifications

*   For HIPAA, **never put PHI in push notification payloads**; even appointment type may be PHI if it implies condition or provider. [hipaavault.com+3medicalwebexperts.com+3GitHub+3](https://www.medicalwebexperts.com/blog/how-to-make-a-hipaa-compliant-healthcare-app/?utm_source=chatgpt.com)
    
*   Use generic messages like: “You have a new message in EMR” and require sign‑in to view details.
    

### 7.5 Audit & monitoring

*   Devices:
    
    *   Ensure app events of interest are forwarded to backend via secure API.
        
*   Backend:
    
    *   Maintain audit logs of:
        
        *   User identity, patient ID, action, timestamp, device/platform.
            
*   Support remote wipe via MDM for corporate‑managed devices.
    

* * *

## 8\. Presentation Layer – Shared View Models (SharedPresentation)

Presentation logic is platform‑agnostic; view models translate use case output into view state.

`// SharedPresentation  @MainActor final class PatientListViewModel: ObservableObject {     @Published var patients: [PatientRowViewModel] = []     @Published var isLoading = false     @Published var errorMessage: String?          private let loadPatientList: LoadPatientListUseCase          init(loadPatientList: LoadPatientListUseCase) {         self.loadPatientList = loadPatientList     }          func load(query: String? = nil) {         Task {             isLoading = true             defer { isLoading = false }             do {                 let result = try await loadPatientList.execute(query: query, page: 0)                 patients = result.map(PatientRowViewModel.init)             } catch {                 errorMessage = "Unable to load patients."             }         }     } }  struct PatientRowViewModel: Identifiable {     let id: PatientID     let displayName: String     let mrn: String?          init(patient: Patient) {         id = patient.id         displayName = "\(patient.name.family), \(patient.name.given)"         mrn = patient.mrn     } }`

* * *

## 9\. Platform‑Specific UI

### 9.1 macOS (AppKit – EMRMac)

Use AppKit for desktop‑grade EMR workflows:

*   **Layout:**
    
    *   `NSSplitViewController`:
        
        *   Left: patient/search list (`NSTableView`).
            
        *   Right: tabbed `NSTabViewController` with Summary, Notes, Orders, Results, Meds.
            
    *   Use `NSCollectionView` or custom views for timeline (Encounters, Observations).
        
*   Bindings:
    
    *   View controllers depend on `PatientListViewModel`, `PatientChartViewModel` from `SharedPresentation`.
        
    *   Use delegation or Combine to observe `@Published` changes.
        

Example:

`final class PatientListViewController: NSViewController {     private let viewModel: PatientListViewModel          @IBOutlet weak var tableView: NSTableView!          init(viewModel: PatientListViewModel) {         self.viewModel = viewModel         super.init(nibName: "PatientListViewController", bundle: nil)     }          required init?(coder: NSCoder) { fatalError() }          override func viewDidLoad() {         super.viewDidLoad()         // bind tableView reloads to viewModel.patients changes (Combine/KVO)         viewModel.load()     } }`

### 9.2 iOS/iPadOS (SwiftUI preferred – EMRiOS / EMRiPadOS)

Use SwiftUI scenes and reuse the same view models.

*   **iPhone:**
    
    *   NavigationStack:
        
        *   PatientListView → PatientSummaryView → subviews (Orders, Results).
            
*   **iPad:**
    
    *   Use `NavigationSplitView` for master‑detail layout.
        
*   Integrate with system features:
    
    *   Handoff between Mac and iPad.
        
    *   Share Sheets for printing/exporting non‑PHI summaries if allowed.
        

Example SwiftUI view:

`struct PatientListView: View {     @StateObject var viewModel: PatientListViewModel          var body: some View {         List(viewModel.patients) { row in             NavigationLink(destination: PatientSummaryView(patientID: row.id)) {                 VStack(alignment: .leading) {                     Text(row.displayName).font(.headline)                     if let mrn = row.mrn {                         Text("MRN: \(mrn)").font(.subheadline)                     }                 }             }         }         .navigationTitle("Patients")         .onAppear { viewModel.load() }         .alert(item: Binding.constant(viewModel.errorMessage)) { msg in             Alert(title: Text("Error"), message: Text(msg), dismissButton: .default(Text("OK")))         }     } }`

### 9.3 watchOS (EMRWatch)

Goals:

*   Quick patient list (e.g., “my assigned patients”).
    
*   Neutral notifications and glanceable info, minimal PHI.
    

Architecture:

*   Watch app is essentially a lightweight client:
    
    *   Uses **WatchConnectivity** to receive:
        
        *   Limited subset of patient data (e.g., first initial + anonymized ID) or pseudonym where policy requires.
            
        *   Or just patient list IDs; watch fetches display names from phone using secure session.
            
*   Notifications:
    
    *   Use APNs for push to iPhone, then local notifications to watch via mirroring.
        
    *   Payload must be generic, no PHI. [medicalwebexperts.com+1](https://www.medicalwebexperts.com/blog/how-to-make-a-hipaa-compliant-healthcare-app/?utm_source=chatgpt.com)
        

Watch SwiftUI example:

`struct WatchPatientListView: View {     @ObservedObject var viewModel: WatchPatientListViewModel          var body: some View {         List(viewModel.patients) { p in             NavigationLink(p.displayName) {                 Text("View details on iPhone") // or a tiny summary if allowed             }         }     } }`

You can also add a complication that shows count of currently admitted or “on‑call patients”.

* * *

## 10\. HL7 Integration Strategy

To keep the Swift clients clean:

*   All HL7 v2/v3 interactions should be handled by backend services, translating to FHIR resources (e.g., ADT^A01 → `Patient`, `Encounter`; ORU → `Observation`).[arXiv+1](https://arxiv.org/abs/1911.12254?utm_source=chatgpt.com)
    
*   The EMR apps consume only FHIR; if you need outbound HL7 (e.g., send ORU, ORM), generate FHIR on client, send to integration layer, then it converts to HL7.
    

* * *

## 11\. Testing & DevOps

*   **Unit tests:**
    
    *   Domain & Use Cases: pure Swift tests.
        
    *   Data layer: mock FHIRClient, local stores.
        
*   **Integration tests:**
    
    *   Run against a test FHIR server (SMART sandbox, HAPI, Azure API for FHIR). [SMART on FHIR+2Microsoft Learn+2](https://docs.smarthealthit.org/?utm_source=chatgpt.com)
        
*   **Security tests:**
    
    *   Verify no PHI in logs.
        
    *   Pen‑testing for auth flows and storage.
        
*   **Compliance:**
    
    *   Ensure policies cover:
        
        *   BAAs with hosting and notification vendors.
            
        *   Incident response and breach notification. [The HIPAA Journal+1](https://www.hipaajournal.com/hipaa-breach-notification-requirements/?utm_source=chatgpt.com)
            

* * *

## 12\. Next Steps / How You Could Implement

1.  Stand up or obtain access to a FHIR R4 sandbox.
    
2.  Create SPM packages for `CoreDomain`, `CoreUseCases`, `FHIRModelsKit`, `DataFHIR`, `DataLocal`, `SecurityKit`, `SharedPresentation`.
    
3.  Implement minimal paths:
    
    *   Auth (SMART on FHIR).
        
    *   Patient search and summary (Patient/Encounter/Observation).
        
4.  Build out:
    
    *   macOS AppKit shell with patient list + summary.
        
    *   iOS/iPadOS SwiftUI app sharing view models.
        
    *   Simple watchOS companion with notifications and patient list.
        
5.  Incrementally add:
    
    *   Orders, meds, lab results.
        
    *   Offline caching and advanced security features.