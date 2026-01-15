import pandas as pd
import geopandas as gpd
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import numpy as np


def calculate_metrics(group):
    """
    Calculates prevalence, sample size, and RSE for a given data group.
    """
    n = len(group)
    weighted_smokers = (group['currentsmoker'] * group['_LLCPWT']).sum()
    total_weight = group['_LLCPWT'].sum()

    if total_weight == 0 or n == 0:
        return pd.Series({'prevalence': np.nan, 'n': n, 'rse': np.nan})

    prevalence = weighted_smokers / total_weight
    sum_weights_sq = (group['_LLCPWT']**2).sum()
    n_eff = (total_weight**2) / sum_weights_sq if sum_weights_sq > 0 else 0

    if n_eff == 0 or prevalence <= 0 or prevalence >= 1:
        rse = np.nan
    else:
        se = np.sqrt((prevalence * (1 - prevalence)) / n_eff)
        rse = (se / prevalence) * 100

    return pd.Series({'prevalence': prevalence, 'n': int(n), 'rse': rse})


def main():
    # --- 1. Load Data ---
    df = pd.read_csv('data/combinedbrfss_18_24v10.csv')
    gdf = gpd.read_file('us-states.json')

    # --- 2. Prepare Data & Calculate Metrics ---
    year_map = {-2: 2018, 4: 2024}
    df['year'] = df['year_centered'].map(year_map)
    df = df[df['year'].isin([2018, 2024])].copy()

    for col in ['_LLCPWT', 'currentsmoker', 'URRU', '_STATE', 'year']:
        df[col] = pd.to_numeric(df[col], errors='coerce')
    df.dropna(subset=['_LLCPWT', 'currentsmoker', 'URRU', '_STATE', 'year'], inplace=True)

    metrics = df.groupby(['_STATE', 'year', 'URRU']).apply(calculate_metrics).reset_index()

    # --- 3. Flag Unreliable Data ---
    # Exclude estimates where RSE > 30% or unweighted sample size < 50
    metrics['is_unreliable'] = (metrics['n'] < 50) | (metrics['rse'] > 30)

    # Build final dataset using observed 2018 and 2024 only
    final_metrics = metrics[metrics['year'].isin([2018, 2024])].copy()
    # Drop prevalence where unreliable to prevent misinterpretation
    final_metrics.loc[final_metrics['is_unreliable'], 'prevalence'] = np.nan

    # --- 4. Merge with GeoDataFrame ---
    gdf = gdf.rename(columns={'name': 'State'})
    state_fips_map = {1:"Alabama",2:"Alaska",4:"Arizona",5:"Arkansas",6:"California",8:"Colorado",9:"Connecticut",10:"Delaware",11:"District of Columbia",12:"Florida",13:"Georgia",15:"Hawaii",16:"Idaho",17:"Illinois",18:"Indiana",19:"Iowa",20:"Kansas",21:"Kentucky",22:"Louisiana",23:"Maine",24:"Maryland",25:"Massachusetts",26:"Michigan",27:"Minnesota",28:"Mississippi",29:"Missouri",30:"Montana",31:"Nebraska",32:"Nevada",33:"New Hampshire",34:"New Jersey",35:"New Mexico",36:"New York",37:"North Carolina",38:"North Dakota",39:"Ohio",40:"Oklahoma",41:"Oregon",42:"Pennsylvania",44:"Rhode Island",45:"South Carolina",46:"South Dakota",47:"Tennessee",48:"Texas",49:"Utah",50:"Vermont",51:"Virginia",53:"Washington",54:"West Virginia",55:"Wisconsin",56:"Wyoming"}
    final_metrics['State'] = final_metrics['_STATE'].map(state_fips_map)

    # --- 5. Create the Plot ---
    fig, axes = plt.subplots(2, 2, figsize=(20, 12), sharex=True, sharey=True)
    panels = {
        (0, 0): {'year': 2018, 'urru': 1}, (0, 1): {'year': 2024, 'urru': 1},
        (1, 0): {'year': 2018, 'urru': 0}, (1, 1): {'year': 2024, 'urru': 0}
    }
    vmin, vmax = 0.05, 0.30

    for (row, col), panel_info in panels.items():
        ax = axes[row, col]
        data_plot = final_metrics[(final_metrics['year'] == panel_info['year']) & (final_metrics['URRU'] == panel_info['urru'])]
        merged_gdf = gdf.merge(data_plot, on='State', how='left')

        merged_gdf[~merged_gdf['State'].isin(['Alaska', 'Hawaii'])].plot(
            column='prevalence', cmap='RdYlGn_r', linewidth=0.8, ax=ax, edgecolor='0.8',
            vmin=vmin, vmax=vmax, missing_kwds={"color": "lightgrey"})
        ax.set_axis_off()

        ax_ak = ax.inset_axes([0.05, 0.0, 0.25, 0.25])
        merged_gdf[merged_gdf['State'] == 'Alaska'].plot(column='prevalence', cmap='RdYlGn_r', ax=ax_ak, vmin=vmin, vmax=vmax, missing_kwds={"color": "lightgrey"})
        ax_ak.set_axis_off()

        ax_hi = ax.inset_axes([0.3, 0.0, 0.2, 0.2])
        merged_gdf[merged_gdf['State'] == 'Hawaii'].plot(column='prevalence', cmap='RdYlGn_r', ax=ax_hi, vmin=vmin, vmax=vmax, missing_kwds={"color": "lightgrey"})
        ax_hi.set_axis_off()

    # --- 6. Titles and Labels ---
    axes[0, 0].set_title("2018", fontsize=30, pad=20)
    axes[0, 1].set_title("2024", fontsize=30, pad=20)
    fig.text(0.08, 0.7, 'Rural', va='center', rotation='vertical', fontsize=30)
    fig.text(0.08, 0.3, 'Urban', va='center', rotation='vertical', fontsize=30)

    # --- 7. Create and Style Horizontal Legend at Bottom ---
    sm = plt.cm.ScalarMappable(cmap='RdYlGn_r', norm=plt.Normalize(vmin=vmin, vmax=vmax))
    sm.set_array([])

    cbar_ax = fig.add_axes([0.25, 0.06, 0.5, 0.03])  # [left, bottom, width, height]
    cbar = fig.colorbar(sm, cax=cbar_ax, orientation='horizontal')
    cbar.set_label("Current smoking prevalence", size=20, labelpad=15)
    cbar.ax.xaxis.set_major_formatter(mticker.PercentFormatter(xmax=1.0, decimals=0))
    cbar.ax.tick_params(labelsize=16)
    cbar.outline.set_edgecolor('lightgrey')
    cbar.outline.set_linewidth(1)

    fig.tight_layout(rect=[0.05, 0.1, 0.95, 1])  # Adjust layout to make space

    plt.savefig('output/figures/smoking_prevalence_map_v9.png', dpi=300, bbox_inches='tight')
    print("Generated map: output/figures/smoking_prevalence_map_v9.png")

    # Print summary statistics
    print("\n=== Data Quality Summary ===")
    for year in [2018, 2024]:
        for urru_val, urru_name in [(0, 'Urban'), (1, 'Rural')]:
            subset = final_metrics[(final_metrics['year'] == year) & (final_metrics['URRU'] == urru_val)]
            total_states = len(subset)
            reliable_states = subset['prevalence'].notna().sum()
            unreliable_states = total_states - reliable_states
            print(f"{year} {urru_name}: {reliable_states}/{total_states} states with reliable estimates ({unreliable_states} excluded)")


if __name__ == '__main__':
    main()
