import os
import pandas as pd

def create_descriptives(df, label, output_suffix):
    """
    Create descriptive statistics table with proper exclusion of missing smoking data.

    Parameters:
    - df: DataFrame with BRFSS data
    - label: Description label (e.g., "2018-2023" or "2018-2024")
    - output_suffix: Suffix for output filename (e.g., "_23" or "_24")
    """

    print("\n" + "=" * 80)
    print(f"DESCRIPTIVE STATISTICS - BRFSS {label}")
    print("Excludes missing smoking status from prevalence calculations")
    print("=" * 80)

    # Total weighted sample size (ALL data)
    total_weight_all = df['_LLCPWT'].sum()

    # Weighted sample with non-missing smoking status
    df_smoking_valid = df[df['currentsmoker'].notna()].copy()
    total_weight_valid_smoking = df_smoking_valid['_LLCPWT'].sum()

    print(f"\nTotal records: {len(df):,}")
    print(f"Total weighted sample (all): {total_weight_all:,.0f}")
    print(f"Records with valid smoking status: {len(df_smoking_valid):,}")
    print(f"Weighted sample (valid smoking): {total_weight_valid_smoking:,.0f}")
    print(f"Missing smoking status: {len(df) - len(df_smoking_valid):,} ({(len(df) - len(df_smoking_valid))/len(df)*100:.1f}%)")

    # Create categorical labels
    df['URRU_cat'] = df['URRU'].map({0: 'Urban', 1: 'Rural'}).fillna('Missing')

    age_map = {
        1: '18-24', 2: '25-34', 3: '35-44',
        4: '45-54', 5: '55-64', 6: '65 or older'
    }
    df['Age_cat'] = df['_AGE_G'].map(age_map).fillna('Missing')

    df['Sex_cat'] = df['SEXVAR'].map({1: 'Male', 2: 'Female'}).fillna('Missing')

    race_map = {
        1: 'Non-Hispanic White', 2: 'Non-Hispanic Black',
        3: 'Non-Hispanic Other', 4: 'Non-Hispanic Multiracial',
        5: 'Hispanic', 9: 'Missing'
    }
    df['Race_cat'] = df['_RACEGR3'].map(race_map).fillna('Missing')

    edu_map = {
        1: 'Did not graduate high school',
        2: 'Graduated high school',
        3: 'Attended college or technical school',
        4: 'Graduated from college or technical school',
        9: 'Missing'
    }
    df['Edu_cat'] = df['_EDUCAG'].map(edu_map).fillna('Missing')

    year_map = {
        -2: '2018', -1: '2019', 0: '2020', 1: '2021',
        2: '2022', 3: '2023', 4: '2024'
    }
    df['Year_cat'] = df['year_centered'].map(year_map).fillna('Missing')

    # Function to compute summary - EXCLUDES MISSING FROM BOTH NUMERATOR AND DENOMINATOR
    def summarize(col_name):
        """
        Compute weighted sample size, percentage, and smoking prevalence.
        EXCLUDES missing smoking status from prevalence calculation (both numerator and denominator).
        """
        grouped = df.groupby(col_name).apply(
            lambda g: pd.Series({
                'Weighted sample size (all)': g['_LLCPWT'].sum(),
                'Percentage (of all)': g['_LLCPWT'].sum() / total_weight_all * 100,
                'Weighted sample (valid smoking)': g[g['currentsmoker'].notna()]['_LLCPWT'].sum(),
                'Smoking prevalence': (
                    (g[g['currentsmoker'].notna()]['_LLCPWT'] * g[g['currentsmoker'].notna()]['currentsmoker']).sum() /
                    g[g['currentsmoker'].notna()]['_LLCPWT'].sum() * 100
                    if g[g['currentsmoker'].notna()]['_LLCPWT'].sum() > 0 else 0
                )
            }),
            include_groups=False
        ).reset_index()
        grouped.columns = [col_name, 'Weighted sample size (all)', 'Percentage (of all)',
                          'Weighted sample (valid smoking)', 'Smoking prevalence']
        return grouped

    # Generate summaries
    urban_rural_summary = summarize('URRU_cat')
    age_summary        = summarize('Age_cat')
    sex_summary        = summarize('Sex_cat')
    race_summary       = summarize('Race_cat')
    edu_summary        = summarize('Edu_cat')
    year_summary       = summarize('Year_cat')

    print("\n=== Urban/Rural ===")
    print(urban_rural_summary.to_string(index=False))

    print("\n=== Age ===")
    print(age_summary.to_string(index=False))

    print("\n=== Sex ===")
    print(sex_summary.to_string(index=False))

    print("\n=== Race/Ethnicity ===")
    print(race_summary.to_string(index=False))

    print("\n=== Education ===")
    print(edu_summary.to_string(index=False))

    print("\n=== Year ===")
    print(year_summary.to_string(index=False))

    # Combine all summaries
    summaries = [
        ('Urban/Rural', urban_rural_summary),
        ('Age', age_summary),
        ('Sex', sex_summary),
        ('Race/Ethnicity', race_summary),
        ('Education', edu_summary),
        ('Year', year_summary),
    ]

    combined_dfs = []
    for name, df_sum in summaries:
        df2 = df_sum.copy()
        first_col = df2.columns[0]
        df2 = df2.rename(columns={first_col: 'Category'})
        df2.insert(0, 'Characteristic', name)
        combined_dfs.append(df2[['Characteristic', 'Category', 'Weighted sample size (all)',
                                 'Percentage (of all)', 'Weighted sample (valid smoking)', 'Smoking prevalence']])

    combined_df = pd.concat(combined_dfs, ignore_index=True)

    # Save to CSV
    script_dir = os.path.dirname(os.path.abspath(__file__))
    csv_file = os.path.join(script_dir, 'output', f'descriptives_summary{output_suffix}.csv')
    combined_df.to_csv(csv_file, index=False)

    print(f"\n{'=' * 80}")
    print(f"Saved to: {csv_file}")
    print(f"Total rows: {len(combined_df)}")
    print(f"{'=' * 80}\n")

    return combined_df


if __name__ == '__main__':
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # Load the full 2018-2024 dataset
    display_path = os.path.join(script_dir, 'data', 'combinedbrfss_18_24v10.csv')
    data_file = display_path
    
    # Create output directory if it doesn't exist
    output_dir = os.path.join(script_dir, 'output')
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    df_all = pd.read_csv(data_file)

    print("=" * 80)
    print("CREATING DESCRIPTIVE STATISTICS WITH PROPER MISSING DATA EXCLUSION")
    print("=" * 80)
    print(f"\nLoaded: {data_file}")
    print(f"Total records: {len(df_all):,}")
    print(f"Years: {sorted(df_all['year_centered'].unique())}")

    # Create 2018-2023 subset
    df_23 = df_all[df_all['year_centered'].isin([-2, -1, 0, 1, 2, 3])].copy()
    print(f"\n2018-2023 subset: {len(df_23):,} records")

    # Create 2018-2024 dataset (all data)
    df_24 = df_all.copy()
    print(f"2018-2024 dataset: {len(df_24):,} records")

    # Generate both versions
    print("\n" + "=" * 80)
    print("GENERATING 2018-2023 DESCRIPTIVES")
    print("=" * 80)
    result_23 = create_descriptives(df_23, "2018-2023", "_23")

    print("\n" + "=" * 80)
    print("GENERATING 2018-2024 DESCRIPTIVES")
    print("=" * 80)
    result_24 = create_descriptives(df_24, "2018-2024", "_24")

    # Print comparison
    print("\n" + "=" * 80)
    print("COMPARISON: YEAR-BY-YEAR SMOKING PREVALENCE")
    print("=" * 80)

    print("\nUsing 2018-2023 dataset (descriptives_summary_23.csv):")
    year_23 = result_23[result_23['Characteristic'] == 'Year'][['Category', 'Weighted sample (valid smoking)', 'Smoking prevalence']]
    print(year_23.to_string(index=False))

    print("\nUsing 2018-2024 dataset (descriptives_summary_24.csv):")
    year_24 = result_24[result_24['Characteristic'] == 'Year'][['Category', 'Weighted sample (valid smoking)', 'Smoking prevalence']]
    print(year_24.to_string(index=False))

    print("\n" + "=" * 80)
    print("FILES CREATED:")
    print("=" * 80)
    print("1. descriptives_summary_23.csv - Statistics for 2018-2023")
    print("2. descriptives_summary_24.csv - Statistics for 2018-2024")
    print("\nBoth files exclude missing smoking status from prevalence calculations.")
    print("=" * 80)
