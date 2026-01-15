"""
Generates Appendix Table 2: State-level Rural vs. Urban Smoking Prevalence
for 2018 & 2023.

Input:
- combinedbrfss_18_23v9.csv: CSV dataset expected in the same directory.
  Required variables: _STATE, year_centered, URRU, currentsmoker, _LLCPWT.

Output:
- appendix_table_2.csv: CSV file saved in the same directory, containing
  the formatted table with columns:
    - STATEFIPS
    - Rural_Prevalence_2018_CI
    - Urban_Prevalence_2018_CI
    - Ratio_2018
    - Rural_Prevalence_2023_CI
    - Urban_Prevalence_2023_CI
    - Ratio_2023
    - Change_In_Ratio
"""
import pandas as pd
import numpy as np
import os

def calculate_prevalence_ci(group):
    '''
    Calculates weighted smoking prevalence, effective sample size (n_eff),
    and the 95% confidence interval (CI) for a given data group.

    Args:
        group (pd.DataFrame): DataFrame subgroup with _LLCPWT (weights) and
                              currentsmoker (0 or 1 indicator).

    Returns:
        pd.Series: Contains 'prevalence', 'n_eff' (effective sample size),
                   'ci_lower' (CI lower bound), 'ci_upper' (CI upper bound),
                   and 'prevalence_ci_str' (formatted string for prevalence and CI).
    '''
    weighted_smokers = (group['_LLCPWT'] * group['currentsmoker']).sum()
    total_weight = group['_LLCPWT'].sum()

    # Handle cases where the group is empty or weights sum to zero
    if total_weight == 0:
        return pd.Series({
            'prevalence': np.nan,
            'n_eff': 0,
            'ci_lower': np.nan,
            'ci_upper': np.nan,
            'prevalence_ci_str': 'N/A'
        })

    prevalence = weighted_smokers / total_weight

    # Calculate effective sample size (Kish's formula for weighted data)
    sum_weights_sq = (group['_LLCPWT']**2).sum()
    if sum_weights_sq == 0:
        n_eff = 0
    else:
        n_eff = (total_weight**2) / sum_weights_sq

    # Calculate 95% CI
    if n_eff == 0 or not (0 <= prevalence <= 1):
        ci_lower = np.nan
        ci_upper = np.nan
        prevalence_ci_str = f"{prevalence*100:.1f}% (N/A)" if not np.isnan(prevalence) else "N/A"
    else:
        p_for_ci = max(0, min(1, prevalence))
        margin_of_error = 1.96 * np.sqrt((p_for_ci * (1 - p_for_ci)) / n_eff)
        ci_lower = max(0, prevalence - margin_of_error)
        ci_upper = min(1, prevalence + margin_of_error)
        prevalence_ci_str = f"{prevalence*100:.1f}% ({ci_lower*100:.1f}% - {ci_upper*100:.1f}%)"

    return pd.Series({
        'prevalence': prevalence,
        'n_eff': n_eff,
        'ci_lower': ci_lower,
        'ci_upper': ci_upper,
        'prevalence_ci_str': prevalence_ci_str
    })

def main():
    """
    Main function to load data, perform calculations, structure the table,
    and save it to a CSV file.
    """
    # --- 1. Load the CSV dataset ---
    script_dir = os.path.dirname(os.path.abspath(__file__))
    csv_file_name = 'combinedbrfss_18_24v10.csv'
    data_file_path = os.path.join(script_dir, 'data', csv_file_name)

    print(f"Attempting to read CSV file: {data_file_path}...")
    try:
        df = pd.read_csv(data_file_path)
        print(f"Successfully read {csv_file_name}.")
    except FileNotFoundError:
        print(f"Error: CSV file not found at {data_file_path}")
        print(f"Please ensure you have run 'convert_to_csv.py' to generate '{csv_file_name}',")
        print(f"or that '{csv_file_name}' is in the same directory as this script.")
        return
    except Exception as e:
        print(f"An error occurred while reading the CSV file: {e}")
        return

    # --- Ensure core columns exist and convert types ---
    core_cols = {
        '_LLCPWT': 'numeric',
        'currentsmoker': 'numeric',
        'URRU': 'numeric',
        '_STATE': 'object',
        'year_centered': 'numeric'
    }

    print("Performing data type conversions for core columns...")
    for col, col_type in core_cols.items():
        if col not in df.columns:
            print(f"Error: Expected column '{col}' not found in the CSV file. Cannot proceed.")
            return
        if col_type == 'numeric':
            df[col] = pd.to_numeric(df[col], errors='coerce')
            if df[col].isnull().any():
                print(f"Warning: Column '{col}' contained non-numeric values converted to NaN.")
        elif col_type == 'object':
            df[col] = df[col].astype(str)

    if df['_LLCPWT'].isnull().all():
        print("Error: All values in '_LLCPWT' are NaN after conversion. Check CSV data quality.")
        return

    if 'year_centered' in df.columns:
        df.dropna(subset=['year_centered'], inplace=True)
    else:
        print("Error: 'year_centered' column is missing. Cannot proceed with year filtering.")
        return

    # --- 2. Filter Data for 2018 and 2024 ---
    df_2018 = df[df['year_centered'] == -2].copy()
    df_2024 = df[df['year_centered'] == 4].copy()

    if df_2018.empty:
        print("Warning: No data found for 2018 (year_centered == -2).")
    else:
        print(f"Filtered {len(df_2018)} records for 2018.")
    if df_2024.empty:
        print("Warning: No data found for 2024 (year_centered == 4).")
    else:
        print(f"Filtered {len(df_2024)} records for 2024.")

    key_calc_cols = ['_LLCPWT', 'currentsmoker', 'URRU', '_STATE']
    df_2018.dropna(subset=key_calc_cols, inplace=True)
    df_2024.dropna(subset=key_calc_cols, inplace=True)

    if df_2018.empty and not df[df['year_centered'] == -2].empty:
        print("Warning: All 2018 data dropped due to missing key columns.")
    if df_2024.empty and not df[df['year_centered'] == 4].empty:
        print("Warning: All 2024 data dropped due to missing key columns.")


    # --- 3. Calculate prevalence & CI for each year/state/URRU ---
    processed_years = {}
    for year_label, df_year_orig in [('2018', df_2018), ('2024', df_2024)]:
        if df_year_orig.empty:
            print(f"Skipping calculations for {year_label} (no data).")
            processed_years[year_label] = pd.DataFrame()
            continue

        print(f"Processing data for {year_label}...")
        df_year = df_year_orig.copy()
        df_year['URRU'] = df_year['URRU'].astype(int)
        df_year['URRU_cat'] = df_year['URRU'].map({0: 'Urban', 1: 'Rural'})

        if df_year['URRU_cat'].isnull().any():
            print(f"Warning: Some URRU values in {year_label} were not 0/1 and will be excluded.")

        summary_df = df_year.groupby(['_STATE', 'URRU_cat']).apply(calculate_prevalence_ci).reset_index()
        if summary_df.empty:
            print(f"No summary data generated for {year_label}.")
        else:
            print(f"Calculated summary statistics for {year_label}.")
        processed_years[year_label] = summary_df

    # --- 4. Pivot and structure each year's summary ---
    final_yearly_data = {}
    for year_label, summary_df in processed_years.items():
        if summary_df.empty:
            print(f"No data to pivot for {year_label}.")
            empty_df = pd.DataFrame(
                columns=['_STATE', f'Rural_Prevalence_{year_label}_CI',
                         f'Urban_Prevalence_{year_label}_CI', f'Ratio_{year_label}']
            ).set_index('_STATE')
            final_yearly_data[year_label] = empty_df
            continue

        pivot_df = summary_df.pivot_table(
            index='_STATE',
            columns='URRU_cat',
            values=['prevalence', 'prevalence_ci_str'],
            aggfunc='first'
        ).reset_index()

        # Flatten MultiIndex columns
        new_columns = []
        for col in pivot_df.columns:
            if isinstance(col, tuple):
                if col[1] == '':
                    new_columns.append(col[0])
                else:
                    new_columns.append(f"{col[0]}_{col[1]}")
            else:
                new_columns.append(col)
        pivot_df.columns = new_columns

        for ur_cat in ['Urban', 'Rural']:
            if f'prevalence_{ur_cat}' not in pivot_df.columns:
                pivot_df[f'prevalence_{ur_cat}'] = np.nan
            if f'prevalence_ci_str_{ur_cat}' not in pivot_df.columns:
                pivot_df[f'prevalence_ci_str_{ur_cat}'] = "N/A"

        pivot_df.rename(columns={
            f'prevalence_ci_str_Rural': f'Rural_Prevalence_{year_label}_CI',
            f'prevalence_ci_str_Urban': f'Urban_Prevalence_{year_label}_CI'
        }, inplace=True)

        pivot_df[f'Ratio_{year_label}'] = pivot_df['prevalence_Rural'] / pivot_df['prevalence_Urban']
        pivot_df.replace([np.inf, -np.inf], np.nan, inplace=True)

        year_final_df = pivot_df[['_STATE',
                                  f'Rural_Prevalence_{year_label}_CI',
                                  f'Urban_Prevalence_{year_label}_CI',
                                  f'Ratio_{year_label}']]
        year_final_df.set_index('_STATE', inplace=True)
        final_yearly_data[year_label] = year_final_df
        print(f"Pivoted and structured data for {year_label}.")

    # --- 5. Merge 2018 & 2024 and compute change in ratio ---
    df_2018_final = final_yearly_data.get('2018')
    df_2024_final = final_yearly_data.get('2024')

    if df_2018_final is None:
        df_2018_final = pd.DataFrame(columns=[
            '_STATE', 'Rural_Prevalence_2018_CI', 'Urban_Prevalence_2018_CI', 'Ratio_2018'
        ]).set_index('_STATE')
    if df_2024_final is None:
        df_2024_final = pd.DataFrame(columns=[
            '_STATE', 'Rural_Prevalence_2024_CI', 'Urban_Prevalence_2024_CI', 'Ratio_2024'
        ]).set_index('_STATE')

    if df_2018_final.empty:
        print("Warning: No processed data available for 2018 to merge.")
    if df_2024_final.empty:
        print("Warning: No processed data available for 2024 to merge.")

    final_table = pd.merge(df_2018_final, df_2024_final, left_index=True, right_index=True, how='outer')
    if 'Ratio_2024' in final_table.columns and 'Ratio_2018' in final_table.columns:
        final_table['Change_In_Ratio'] = final_table['Ratio_2024'] - final_table['Ratio_2018']
    else:
        print("Warning: Missing ratio columns; setting Change_In_Ratio to NaN.")
        final_table['Change_In_Ratio'] = np.nan

    final_table.reset_index(inplace=True)
    # Rename the index column to STATEFIPS
    final_table.rename(columns={'_STATE': 'STATEFIPS'}, inplace=True)
    # Convert STATEFIPS from string to integer type for mapping to state names
    final_table['STATEFIPS'] = pd.to_numeric(final_table['STATEFIPS'], errors='coerce').astype('Int64')

    # --- 6. Map STATEFIPS codes to state names ---
    state_map = {
        1:  "Alabama",             2:  "Alaska",               4:  "Arizona",
        5:  "Arkansas",            6:  "California",           8:  "Colorado",
        9:  "Connecticut",        10:  "Delaware",            11:  "District of Columbia",
       12:  "Florida",            13:  "Georgia",             15:  "Hawaii",
       16:  "Idaho",              17:  "Illinois",            18:  "Indiana",
       19:  "Iowa",               20:  "Kansas",              22:  "Louisiana",
       23:  "Maine",              24:  "Maryland",            25:  "Massachusetts",
       26:  "Michigan",           27:  "Minnesota",           28:  "Mississippi",
       29:  "Missouri",           30:  "Montana",             31:  "Nebraska",
       32:  "Nevada",             33:  "New Hampshire",       34:  "New Jersey",
       35:  "New Mexico",         36:  "New York",            37:  "North Carolina",
       38:  "North Dakota",       39:  "Ohio",                40:  "Oklahoma",
       41:  "Oregon",             44:  "Rhode Island",        45:  "South Carolina",
       46:  "South Dakota",       47:  "Tennessee",           48:  "Texas",
       49:  "Utah",               50:  "Vermont",             51:  "Virginia",
       53:  "Washington",         54:  "West Virginia",       55:  "Wisconsin",
       56:  "Wyoming",            66:  "Guam",                72:  "Puerto Rico",
       78:  "Virgin Islands"
    }

    final_table['State'] = final_table['STATEFIPS'].map(state_map)
    final_table.drop(columns=['STATEFIPS'], inplace=True)

    # Final column order
    column_order = [
        'State',
        'Rural_Prevalence_2018_CI',
        'Urban_Prevalence_2018_CI',
        'Ratio_2018',
        'Rural_Prevalence_2024_CI',
        'Urban_Prevalence_2024_CI',
        'Ratio_2024',
        'Change_In_Ratio'
    ]
    for col in column_order:
        if col not in final_table.columns:
            final_table[col] = np.nan
            print(f"Warning: Column '{col}' was missing and has been added.")

    final_table = final_table[column_order]

    print("\n--- Combined Table (First 5 rows) ---")
    print(final_table.head())

    # --- 7. Save Output to CSV ---
    output_csv_file = os.path.join(script_dir, 'output', 'tables', 'appendix_table_2_2018_2024.csv')
    try:
        final_table.to_csv(output_csv_file, index=False)
        print(f"\nSuccessfully saved the final table to: {output_csv_file}")
    except Exception as e:
        print(f"\nError saving the table to CSV: {e}")

if __name__ == '__main__':
    main()
