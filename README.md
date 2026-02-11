# Urban-Rural Differences in Adult Smoking Prevalence, 2018-2024: Analysis of BRFSS Data

This repository contains the analytic code for a study examining urban-rural disparities in current smoking prevalence among U.S. adults from 2018 to 2024, using data from the Behavioral Risk Factor Surveillance System (BRFSS).

## Citation

> [Author(s)]. Urban-Rural Differences in Adult Smoking Prevalence, 2018-2024. *[Journal Name]*. [Year]. [DOI].

*(Update with final publication details.)*

---

## Data Availability

### Source Data

This study uses public-use data from the **CDC Behavioral Risk Factor Surveillance System (BRFSS)**, years 2018-2024. The annual LLCP SAS Transport (.XPT) files can be downloaded from:

- [CDC BRFSS Annual Survey Data](https://www.cdc.gov/brfss/annual_data/annual_data.htm)

Download the following files and place them in the `data/` directory:

| File | Description |
|------|-------------|
| `LLCP2018.XPT` | 2018 BRFSS Combined Landline and Cell Phone data |
| `LLCP2019.XPT` | 2019 BRFSS Combined Landline and Cell Phone data |
| `LLCP2020.XPT` | 2020 BRFSS Combined Landline and Cell Phone data |
| `LLCP2021.XPT` | 2021 BRFSS Combined Landline and Cell Phone data |
| `LLCP2022.XPT` | 2022 BRFSS Combined Landline and Cell Phone data |
| `LLCP2023.XPT` | 2023 BRFSS Combined Landline and Cell Phone data |
| `LLCP2024.XPT` | 2024 BRFSS Combined Landline and Cell Phone data |

### Combined Analytic File

The analysis scripts expect a single combined CSV file: **`data/combinedbrfss_18_24v10.csv`**. This file is created by appending the yearly BRFSS files and deriving the following key variables:

| Variable | Description | Derivation |
|----------|-------------|------------|
| `currentsmoker` | Current smoker (binary: 0/1) | Recoded from `_RFSMOK3` |
| `URRU` | Urban-rural status (binary: 0=Urban, 1=Rural) | Derived from `_URBSTAT` (2019-2024) and `MSCODE` (2018) |
| `year_centered` | Survey year centered at 2020 | `IYEAR - 2020` |
| `Quit` | Former smoker (binary: 0/1) | Derived from `_SMOKER3` |

### GeoJSON

The file `us-states.json` (state boundary GeoJSON for map generation) is included in the repository.

---

## Repository Structure

### Analysis Pipeline

Scripts are organized by analysis stage. All scripts assume they are run from the **repository root directory**.

```
repo-root/
|-- data/                          # User-supplied data (not included)
|   |-- combinedbrfss_18_24v10.csv
|   `-- LLCP20{18..24}.XPT        # Optional raw files
|
|-- output/                        # Generated output (not included)
|   |-- tables/
|   |-- reports/
|   `-- figures/
|
|-- CS_QR_finalresults17_fixed_inter.sas   # [Step 1] State-level logistic models
|-- Nationwide_analysis.sas                # [Step 2] Nationwide models (current + former smoking)
|-- nationwide_genmod_gee_analysis.sas     # [Step 3] Nationwide GEE models
|-- nationwide_clustered_logit_analysis.do # [Step 4] Nationwide clustered logit (Stata)
|-- SimpleSlopes_v17_significant.sas       # [Step 5] Simple slopes for significant interactions
|-- sas_panel_final.sas                    # [Step 6] Predicted probability panel (SAS)
|-- panel_predicted_probs_15states.do      # [Step 7] Predicted probability panel (Stata)
|-- descriptives_final.py                  # [Step 8] Descriptive statistics tables
|-- generate_smoking_prevalence_map_v9.py  # [Step 9] Smoking prevalence choropleth maps
|-- generate_choropleth_geopandas_v26.py   # [Step 10] Odds ratio choropleth maps
|-- appendix_table_2_updated.py            # [Step 11] Appendix Table 2
|-- us-states.json                         # State boundary GeoJSON
`-- README.md
```

### Script Descriptions

| Script | Software | Purpose |
|--------|----------|---------|
| `CS_QR_finalresults17_fixed_inter.sas` | SAS | State-level survey logistic regression (Models 1, 2, 3, 3b) for all 50 states + nationwide. Exports odds ratios to CSV and Excel. |
| `Nationwide_analysis.sas` | SAS | Nationwide survey logistic models for current and former smoking (Models 1, 2, 3). |
| `nationwide_genmod_gee_analysis.sas` | SAS | Nationwide GEE logistic regression with exchangeable correlation and state-level clustering (Models 1, 2, 3a, 3b). Includes predicted probabilities. |
| `nationwide_clustered_logit_analysis.do` | Stata | Nationwide logistic regression with cluster-robust SEs by state (Models 1, 2, 3a, 3b). Produces predicted probability plots and an Excel export. |
| `SimpleSlopes_v17_significant.sas` | SAS | Simple-slope odds ratios for the year effect at each level of urban-rural status, for states with significant interactions. |
| `sas_panel_final.sas` | SAS | 3x5 panel figure of predicted probabilities (Model 3b) for nationwide + 14 states with significant interactions. |
| `panel_predicted_probs_15states.do` | Stata | Equivalent panel figure to `sas_panel_final.sas`, produced in Stata with survey-weighted logistic regression. |
| `descriptives_final.py` | Python | Weighted descriptive statistics (sample sizes, smoking prevalence) by urban-rural status, age, sex, race, education, and year. |
| `generate_smoking_prevalence_map_v9.py` | Python | Four-panel choropleth map of state-level smoking prevalence (2018 vs 2024, urban vs rural). |
| `generate_choropleth_geopandas_v26.py` | Python | Choropleth maps of state-level rural-vs-urban odds ratios from Models 1, 2, and 3. |
| `appendix_table_2_updated.py` | Python | State-level rural vs urban prevalence, prevalence ratios, and change from 2018 to 2024 (Appendix Table 2). |

---

## Models

The analysis uses a stepwise modeling approach:

| Model | Specification |
|-------|---------------|
| **Model 1** | `URRU + year_centered` |
| **Model 2** | Model 1 + `_AGE_G` + `SEXVAR` + `_RACEGR3` |
| **Model 3 / 3a** | Model 2 + `_EDUCAG` |
| **Model 3b** | Model 3 + `URRU * year_centered` interaction |

- **Outcome**: `currentsmoker` (binary)
- **Primary predictor**: `URRU` (0 = Urban, 1 = Rural)
- **Time variable**: `year_centered` (continuous, centered at 2020)
- **Survey design**: weighted by `_LLCPWT`, stratified by `_STSTR`, clustered by `_PSU`

---

## Key Variables

| Variable | Construct | Source |
|----------|-----------|--------|
| `currentsmoker` | Current smoking status (0/1) | Derived from `_RFSMOK3` |
| `URRU` | Urban (0) vs Rural (1) | Derived from `_URBSTAT` / `MSCODE` |
| `year_centered` | Year centered at 2020 | Derived from `IYEAR` |
| `_AGE_G` | Age group (6 categories) | BRFSS calculated variable |
| `SEXVAR` / `_SEX` | Sex | BRFSS core / calculated variable |
| `_RACEGR3` | Race/ethnicity (5 categories) | BRFSS calculated variable |
| `_EDUCAG` | Education level (4 categories) | BRFSS calculated variable |
| `_LLCPWT` | Final survey weight | BRFSS design variable |
| `_STSTR` | Stratification variable | BRFSS design variable |
| `_PSU` | Primary sampling unit | BRFSS design variable |
| `_STATE` | State FIPS code | BRFSS identifier |

---

## Software Requirements

| Software | Version | Used For |
|----------|---------|----------|
| **SAS** | 9.4+ | PROC SURVEYLOGISTIC, PROC GENMOD, PROC LOGISTIC, PROC PLM |
| **Stata** | 17+ | `svy: logistic`, `margins`, `logit` with `vce(cluster)` |
| **Python** | 3.8+ | Descriptive tables, choropleth maps, appendix tables |

### Python Packages

```
pandas
numpy
geopandas
matplotlib
```

---

## How to Run

### Prerequisites

1. Download BRFSS data files from the CDC (see [Data Availability](#data-availability)).
2. Prepare the combined analytic file `combinedbrfss_18_24v10.csv` and place it in `data/`.
3. Create the output directory structure:
   ```
   mkdir -p output/tables output/reports output/figures
   ```

### Execution Order

Run scripts from the **repository root directory** in the following order:

| Step | Script | Software | Output |
|------|--------|----------|--------|
| 1 | `CS_QR_finalresults17_fixed_inter.sas` | SAS | State-level OR tables (Excel + CSV) |
| 2 | `Nationwide_analysis.sas` | SAS | Nationwide model results (log) |
| 3 | `nationwide_genmod_gee_analysis.sas` | SAS | GEE results (HTML + Excel) |
| 4 | `nationwide_clustered_logit_analysis.do` | Stata | Clustered logit results, plots, Excel |
| 5 | `SimpleSlopes_v17_significant.sas` | SAS | Simple slope ORs (CSV + Excel) |
| 6 | `sas_panel_final.sas` | SAS | Predicted probability panel (PNG + CSV) |
| 7 | `panel_predicted_probs_15states.do` | Stata | Predicted probability panel (PNG + PDF) |
| 8 | `descriptives_final.py` | Python | Descriptive statistics (CSV) |
| 9 | `generate_smoking_prevalence_map_v9.py` | Python | Prevalence choropleth map (PNG) |
| 10 | `generate_choropleth_geopandas_v26.py` | Python | OR choropleth map (PNG) |
| 11 | `appendix_table_2_updated.py` | Python | Appendix Table 2 (CSV) |

**Notes:**
- Step 10 (`generate_choropleth_geopandas_v26.py`) requires the CSV output from Step 1.
- Steps 6 and 7 produce equivalent panel figures in SAS and Stata, respectively.
- Stata scripts change directory to `output/` at the start and reference data via `../data/`.
- SAS and Python scripts use paths relative to the repo root.

---

## States with Significant Urban-Rural x Year Interactions

The following 14 states (plus nationwide) showed statistically significant interactions between urban-rural status and year in Model 3b:

Arizona, Arkansas, Colorado, Georgia, Iowa, Kansas, Maine, Mississippi, Missouri, Montana, Nebraska, South Carolina, Washington, Wisconsin

These states are the focus of the simple slopes analysis and the predicted probability panel figures.

---

## License

This repository contains analytic code only. The underlying BRFSS data are publicly available from the CDC and are subject to CDC data use agreements.
