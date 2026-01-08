# bEMR

Initial scaffolding for a modular EMR in Swift, aligned with the clean architecture blueprint and FHIR/SMART on FHIR. Includes reference targets for macOS (AppKit), iOS/iPadOS (SwiftUI), and watchOS with domain layers, use cases, data (FHIR + SwiftData cache), and shared UI.

## Screenshots

| Patient List (macOS) | Patient Health Record (macOS) |
|---|---|
| ![Patient List - macOS](Screenshots/Patient%20List%20-%20macOS.png) | ![Patient Health Record - macOS](Screenshots/Patient%20Health%20Record%20-%20macOS.png) |

| Patient List (iPad) | Schedule (iPad) |
|---|---|
| ![Patient List - iPad](Screenshots/Patient%20List%20-%20iPad.png) | ![Schedule - iPad](Screenshots/Schedule%20-%20iPad.png) |

## SwiftPM Modules
- `CoreDomain`: entities and repository protocols.
- `CoreUseCases`: use cases (list, summary, lookup by identifier, encounter timeline, vitals).
- `FHIRModelsKit`: re-exports `ModelsR4` (Apple FHIRModels).
- `SecurityKit`: session/token (Keychain, refresh).
- `DataFHIR`: `FHIRClient` + remote repositories and domain↔FHIR mappers.
- `DataLocal`: local caches via SwiftData (persistent or in-memory `ModelContainer`) and decorators.
- `SharedPresentation`: shared view models.
- `AppSharedUI`: dependency composition (demo or live) + reusable SwiftUI views.

## Reference apps (entry points)
- `Apps/EMRiOS`: SwiftUI `NavigationStack`.
- `Apps/EMRiPadOS`: `NavigationSplitView`.
- `Apps/EMRMac`: AppKit with `NSHostingView`.
- `Apps/EMRWatch`: lightweight patient list.
- `Apps/SharedUI`: composition (`AppEnvironmentFactory`, `LiveComposition`, `DemoComposition`) and views (`PatientListView`, `PatientSummaryView`).

## Live vs demo environment
`AppEnvironmentFactory.makeDefault()` tries to use a real FHIR endpoint; if env vars are missing it falls back to demo data.
- Set before running/compiling:
  - `FHIR_BASE_URL=https://fhir.sandbox.example.com`
  - `FHIR_STATIC_TOKEN=ey...` (sandbox bearer token)
- For production, replace the static token with `LiveAuthFactory.makeTokenProvider` using a refresh closure (SMART on FHIR + PKCE) that returns `AuthToken` and persist it in the Keychain.
- Cache: `LocalContainerFactory.makePersistent()` (SwiftData) is already used in the factory; switch to in-memory if needed.

## Tests
- Run: `swift test`
- Current coverage: `CoreDomainTests`, `CoreUseCasesTests`. (Suggestion: add tests for FHIR→domain mapping and SwiftData cache.)

## How to integrate in Xcode
1. Add the local package (`Package.swift`) to the workspace/project.
2. Point app targets to the `AppSharedUI` module and enable minimum platforms (macOS 14 / iOS 17 / watchOS 10) for SwiftData.
3. Configure schemes to inject `FHIR_BASE_URL` and token via env vars or implement the SMART flow in the refresh closure.

## Suggested next steps
1) Implement the full SMART on FHIR flow (Authorization Code + PKCE) in the `AuthSessionManager` refresh closure.  
2) Adjust FHIR→domain mappings per server (local terminologies, MRN, encounter class).  
3) Add integration tests for FHIRClient/repositories using a SMART sandbox.  
4) Harden local persistence (per-platform file protection, avoid PHI in logs).  
5) Expand use cases/view models for orders, meds, labs, and secure messaging.

## Notes
- The repo still contains the original `bEMR.xcodeproj` template; use the new SwiftPM layout to build the workspace.  
- Network dependencies point to `https://github.com/apple/FHIRModels.git` (R4). Configure the SMART on FHIR endpoint and scopes per provider.
