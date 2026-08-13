# 🧬 CDISC Clinical Data Pipeline (Raw to SDTM/ADaM)

An end-to-end clinical data engineering and statistical programming pipeline. This repository demonstrates the transformation of raw, unstructured Electronic Data Capture (EDC) exports into fully compliant **CDISC SDTM (Study Data Tabulation Model)** and **ADaM (Analysis Data Model)** datasets, ready for FDA/EMA regulatory submission.

## 🚀 Core Engineering Philosophy
This project strictly adheres to pharmaceutical industry standards, focusing on determinism, traceability, and clinical validation:
1. **Regulatory Compliance:** Output datasets conform to the CDISC Implementation Guides (SDTMIG and ADaMIG).
2. **Defensive SAS Programming:** Extensive use of dynamic type-checking (`vtype`), `anydtdte` informats, and robust ISO 8601 date conversions (`is8601da.`) to prevent data loss from unstructured EDC formats.
3. **Advanced Derivations:** Complex logic for ongoing clinical events, baseline flagging (`ABLFL`), and temporal treatment-emergent derivations (`TRTEMFL`).

## 📂 Repository Architecture
The structure mirrors a standard Contract Research Organization (CRO) environment:
* `data/raw/` - Simulated raw EDC data containing intentional structural noise.
* `data/sdtm/` - Standardized SDTM datasets (DM, VS, AE, EX, LB).
* `data/adam/` - Statistical analysis datasets (ADSL, ADAE, ADVS).
* `programs/` - Core SAS mapping scripts.
* `scripts/` - Python utilities used strictly for generating synthetic EDC clinical trial data.

## 🛠️ Development Milestones

### Phase 1: SDTM Transformation (Completed)
- **DM (Demographics):** Core subject identifiers and ISO 8601 date standardizations.
- **VS (Vital Signs):** Horizontal-to-vertical unpivoting (transposition) using explicit OUTPUT statements.
- **AE (Adverse Events):** Sequential numbering (`AESEQ`) and logic for handling ongoing events without end dates.
- **EX (Exposure):** Study drug administration mapping.
- **LB (Laboratory):** Conditional dictionary mapping (`select/when`) and rigorous SI unit standardization.

### Phase 2: ADaM Derivation (Completed)
- **ADSL (Subject-Level):** The statistical backbone. Derivation of numeric analysis dates, demographic math (AGE), Treatment Duration (`TRTDURD`), and Safety/ITT Population Flags (`SAFFL`).
- **ADAE (Adverse Events Analysis):** Temporal derivations to identify Treatment-Emergent Adverse Events (`TRTEMFL`) and Analysis Relative Days (`ASTDY`).
- **ADVS (Vital Signs Analysis):** Advanced Baseline derivations (`ABLFL`), resolving retained PDV (Program Data Vector) edge cases, and calculating Change from Baseline (`CHG`).

## 💻 Tech Stack
* **SAS (Base Language):** Core analytical engine for deterministic SDTM/ADaM derivations.
* **Python (Pandas):** Used exclusively to simulate the data quality issues typically found in real-world EDC systems.