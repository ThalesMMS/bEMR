# bEMR

- **What’s implemented (demo-only)**
  - Patient list with rich mock columns, filters/badges, priority highlights.
  - Patient summary tabs: History (anamnesis), ICD/Diagnoses, Allergies, Exams, Prescription, Progress Notes — all populated with mock data.
  - Prescription/Progress Notes: timelines, add/edit/delete/sign flows backed by in-memory stores persisted via UserDefaults; audit trail per action shown in context.
  - Agenda split view (queue + detail) with status chips and cards.
  - Sidebar modules (hospitalization, opinion, nursing, discharge, chart review) with lightweight demo forms/timelines.

- **Data**
  - All data is mock/demo; no backend/FHIR calls.
  - Persistence: UserDefaults only (per patient, per store) for RX/Evolution edits and audit entries.

- **Run / Preview**
  - Open `bEMR.xcworkspace`, run `EMRMac` target (macOS 14+). Defaults to demo composition.
  - SwiftUI previews: PatientSummaryView (demo-001, demo-012), PatientListView, AgendaSplitView.
  - CLI: `swift test` (currently green).

- **Demo vs. Production**
  - No real auth/network/storage; validation is minimal and non-clinical.
  - Flows are illustrative only; do not use with real PHI.

- **Next-step gaps**
  - No backend/live queue or real chart review; agenda not live-updating.
  - Audit is basic (UserDefaults), no per-med server trace.
  - Sidebar modules still shallow demos; production forms, signatures, and integrations needed.
