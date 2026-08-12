# 🧬 CDISC Clinical Data Pipeline (Raw to SDTM/ADaM)

An end-to-end clinical data engineering and statistical programming pipeline. This repository demonstrates the transformation of raw, unstructured Electronic Data Capture (EDC) exports into fully compliant **CDISC SDTM (Study Data Tabulation Model)** and **ADaM (Analysis Data Model)** datasets, ready for FDA/EMA regulatory submission.

## 🚀 Core Engineering Philosophy
This project strictly adheres to pharmaceutical industry standards, focusing on determinism, traceability, and clinical validation:
1. **Regulatory Compliance:** Output datasets conform to the CDISC Implementation Guides (SDTMIG).
2. **Defensive SAS Programming:** Extensive use of dynamic type-checking (`vtype`), `anydtdte` informats, and robust ISO 8601 date conversions (`is8601da.`) to prevent data loss from unstructured EDC formats.
3. **Macro-Driven Architecture:** Reusable SAS macros for standardized derivations (e.g., vital signs unit conversions, baseline flagging).

## 📂 Repository Architecture
The structure mirrors a standard Contract Research Organization (CRO) environment:
* `data/raw/` - Simulated raw EDC data (Demographics, Vitals, Adverse Events).
* `data/sdtm/` - Standardized SDTM datasets (`.sas7bdat`).
* `data/adam/` - Statistical analysis datasets (Pending Phase 2).
* `programs/` - Core SAS mapping scripts (e.g., `sdtm_dm.sas`).
* `macros/` - Reusable SAS macro library.
* `scripts/` - Python utilities used strictly for generating synthetic EDC clinical trials data.

## 🛠️ Current Development Status
- [x] **Phase 1.1:** Data generation and environmental setup (Python).
- [x] **Phase 1.2:** SDTM DM (Demographics) domain mapping and ISO 8601 alignment.
- [ ] **Phase 1.3:** SDTM VS (Vital Signs) & AE (Adverse Events) domains.
- [ ] **Phase 2.0:** ADaM derivations (ADSL, ADVS).

## 💻 Tech Stack
* **SAS (Base & Macro Language):** Core analytical engine for SDTM/ADaM derivations.
* **Python (Pandas):** Used exclusively for deterministic EDC clinical data simulation.