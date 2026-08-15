# 🧬 CDISC-Inspired Clinical Data Pipeline (Raw to SDTM/ADaM)

An educational end-to-end clinical data pipeline demonstrating the transformation of raw, unstructured Electronic Data Capture (EDC) exports into **CDISC SDTM (Study Data Tabulation Model)** and **ADaM (Analysis Data Model)** datasets. 

This project is designed to showcase clinical data engineering, defensive SAS programming, and statistical analysis dataset derivation.

## 🚀 Core Engineering Philosophy
* **Educational Terminology Mapping:** Utilizes mock dictionaries to simulate MedDRA and CDISC Controlled Terminology mapping.
* **Defensive SAS Programming:** Extensive use of dynamic type-checking (`vtype`), `anydtdte` informats, and robust ISO 8601 date conversions (`is8601da.`) to prevent data loss from unstructured EDC formats.
* **Advanced Derivations:** Complex logic for ongoing clinical events, baseline flagging (`ABLFL`), and temporal treatment-emergent derivations (`TRTEMFL`).

## 📂 Target Architecture
The pipeline follows a metadata-driven ETL approach with integrated Quality Control (QC) and presentation layers:

RAW EDC ──▶ Data Cleaning ──▶ SDTM (DM, AE, EX, LB, VS) ──▶ ADaM (ADSL, ADAE, ADVS) ──▶ QC Framework ──▶ TLFs

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

### Phase 3: Quality Control & TLFs
- **QC Framework:** Automated `PROC SQL` validation scripts to detect duplicate baselines, chronological anomalies (e.g., AE end date before start date), and referential integrity issues across domains.
- **TLFs (Tables, Listings, Figures):** Generation of regulatory-grade RTF outputs, including "Table 1: Demographics and Baseline Characteristics" (Intent-to-Treat population), utilizing `PROC TABULATE` and the SAS Output Delivery System (ODS).

## ⚙️ How to Reproduce this Pipeline

To run this project locally or in SAS OnDemand for Academics (SODA):

1. **Clone the repository:**
   `git clone [https://github.com/your-username/Clinical-data-to-cdisc.git](https://github.com/your-username/Clinical-data-to-cdisc.git)`

2. **Generate the Raw Data:**
   Run the Python engine to simulate the imperfect clinical data extraction.
   `python scripts/generate_raw_edc.py`

3. **Configure the SAS Environment:**
   * Upload the repository to your SAS environment.
   * Open `programs/00_setup.sas`.
   * Modify the `%let project_path = ...` variable to match your root directory.
   * Run `00_setup.sas` to initialize the global libraries (`raw`, `sdtm`, `adam`).

4. **Execute the Pipeline:**
   Run the SDTM domains sequentially, followed by the ADaM domains.