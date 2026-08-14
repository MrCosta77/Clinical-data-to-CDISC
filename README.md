# 🧬 CDISC-Inspired Clinical Data Pipeline (Raw to SDTM/ADaM)

An educational end-to-end clinical data pipeline demonstrating the transformation of raw, unstructured Electronic Data Capture (EDC) exports into **CDISC SDTM (Study Data Tabulation Model)** and **ADaM (Analysis Data Model)** datasets. 

This project is designed to showcase clinical data engineering, defensive SAS programming, and statistical analysis dataset derivation.

## 🚀 Core Engineering Philosophy
* **Educational Terminology Mapping:** Utilizes mock dictionaries to simulate MedDRA and CDISC Controlled Terminology mapping.
* **Defensive SAS Programming:** Extensive use of dynamic type-checking (`vtype`), `anydtdte` informats, and robust ISO 8601 date conversions (`is8601da.`) to prevent data loss from unstructured EDC formats.
* **Advanced Derivations:** Complex logic for ongoing clinical events, baseline flagging (`ABLFL`), and temporal treatment-emergent derivations (`TRTEMFL`).

## 📂 Target Architecture
The project is evolving towards a metadata-driven ETL pipeline with integrated Quality Control (QC):

RAW EDC ──▶ Data Cleaning ──▶ SDTM (DM, AE, EX, LB, VS) ──▶ ADaM (ADSL, ADAE, ADVS) ──▶ QC Framework

## 🛠️ Development Milestones

### Phase 1: SDTM Transformation
- **DM:** Core subject identifiers, ISO 8601 date standardizations, and Randomization Arms.
- **VS:** Horizontal-to-vertical unpivoting (wide to long) using explicit OUTPUT statements.
- **AE:** Sequential numbering (`AESEQ`) and handling of ongoing events without end dates.
- **EX:** Study drug administration mapping.
- **LB:** Conditional dictionary mapping and unit representation standardization.

### Phase 2: ADaM Derivation
- **ADSL (Subject-Level):** Derivation of numeric analysis dates, demographic math (AGE), Treatment Duration (`TRTDURD`), and separation of Planned vs. Actual treatments (`TRT01P` vs `TRT01A`).
- **ADAE (Adverse Events Analysis):** Temporal derivations to identify Treatment-Emergent Adverse Events (`TRTEMFL`).
- **ADVS (Vital Signs Analysis):** Advanced Baseline derivations (`ABLFL`) resolving retained PDV memory, and Change from Baseline (`CHG`).