import pandas as pd
import geopandas as gpd
import matplotlib.pyplot as plt
import numpy as np
from mpl_toolkits.axes_grid1.inset_locator import inset_axes


def parse_p(val):
    """Parse p-value, handling '<' character and scientific notation."""
    try:
        if pd.isna(val):
            return np.nan
        if isinstance(val, str):
            if val.startswith('<'):
                return float(val.strip('<'))
            # Handle scientific notation like "1.82335E-124"
            return float(val)
        return float(val)
    except (ValueError, TypeError):
        return np.nan


def get_or_category(row, q1, q2):
    """Categorize state based on odds ratio and significance.

    Separation rules:
    - Rural sample size: n < 50 when the state is absent from logistic_or_by_state_v17.csv
    - Non-significant: state present in results, but p >= 0.05 or OR/p missing
    - OR < 1.0: significant with OR < 1.0
    - Otherwise, use OR thresholds for rural > urban
    """
    # Check if state is not in the results file (insufficient rural sample)
    if not row['present_in_results']:
        return 'Rural sample size: n < 50'
    if pd.isna(row['OR']) or pd.isna(row['p']) or row['p'] >= 0.05:
        return 'Non-significant'
    if row['OR'] < 1.0:
        return 'OR < 1.0'
    if row['OR'] <= 1.25:
        return 'OR ≤ 1.25'
    if row['OR'] < 1.5:
        return '1.25 < OR < 1.50'
    return 'OR ≥ 1.50'


def main():
    # Load data - carried forward for v26
    # Load data - updated for relative paths in Updated Analysis
    df = pd.read_csv('output/tables/logistic_or_by_state_v17.csv')
    dfr = pd.read_csv('data/combinedbrfss_18_24v10.csv', usecols=['_STATE', 'URRU'])
    gdf = gpd.read_file('us-states.json')

    # Prepare data
    rural_counts = dfr[dfr['URRU'] == 1].groupby('_STATE').size()
    df['_STATE'] = df['State_Code'].astype(int)
    df['rural_n'] = df['_STATE'].map(rural_counts).fillna(0).astype(int)

    # Map state names (handle truncated names in v17 output)
    state_name_map = {
        'Nationwide': 'Nationwide',
        'North_Dako': 'North Dakota',
        'South_Dako': 'South Dakota',
        'Mississipp': 'Mississippi',
        'North_Caro': 'North Carolina',
        'South_Caro': 'South Carolina',
        'Pennsylvan': 'Pennsylvania',
        'West_Virgi': 'West Virginia',
        'New_Mexico': 'New Mexico',
        'New_York': 'New York'
    }
    # For other states, just replace underscores with spaces
    df['State'] = df['State_Name'].map(lambda x: state_name_map.get(x, x.replace('_', ' ')))

    # Track which states are present in the results file (n>=50 for rural sample)
    states_in_results = set(df['State'].dropna().astype(str))

    gdf = gdf.rename(columns={'name': 'State'})
    gdf = gdf.merge(df, on='State', how='left')

    # Presence flag per state
    gdf['present_in_results'] = gdf['State'].astype(str).isin(states_in_results)

    # Models to plot - updated column names for v17
    models = [
        ('Model 1', 'OR_Model1', 'PValue_Model1'),
        ('Model 2', 'OR_Model2', 'PValue_Model2'),
        ('Model 3a', 'OR_Model3', 'PValue_Model3')
    ]

    # Neutral colors for non-OR buckets
    base_colors = {
        'Non-significant': '#d9d9d9',  # light grey
        'Rural sample size: n < 50': '#969696',  # darker grey
        'OR < 1.0': '#fee090',  # yellow/cream (opposite of rural higher)
    }

    fig = plt.figure(figsize=(20, 15))
    gs = fig.add_gridspec(2, 2)

    ax1 = fig.add_subplot(gs[0, 0])
    ax2 = fig.add_subplot(gs[0, 1])
    ax3 = fig.add_subplot(gs[1, :])

    axes = [ax1, ax2, ax3]

    for i, (title, or_col, p_col) in enumerate(models):
        ax = axes[i]
        gdf['OR'] = pd.to_numeric(gdf[or_col], errors='coerce')
        gdf['p'] = gdf[p_col].apply(parse_p)

        # Calculate quartiles for significant ORs (only for states present in results with OR >= 1)
        mask_sig = (gdf['p'] < 0.05) & gdf['present_in_results'] & gdf['OR'].notna() & (gdf['OR'] >= 1.0)
        or_sig = gdf.loc[mask_sig, 'OR']
        if not or_sig.empty:
            q1, q2 = np.percentile(or_sig, [33.33, 66.67])
        else:
            q1 = q2 = np.nan

        # Assign categories
        gdf['category'] = gdf.apply(get_or_category, axis=1, q1=q1, q2=q2)

        # Define colors for this model
        or_colors = {
            'OR ≤ 1.25': '#a6bddb',
            '1.25 < OR < 1.50': '#3690c0',
            'OR ≥ 1.50': '#034e7b'
        }
        model_colors = {**base_colors, **or_colors}

        # Map colors to categories
        gdf['plot_color'] = gdf['category'].map(model_colors).fillna('white')

        # Plot continental US
        gdf[~gdf['State'].isin(['Alaska', 'Hawaii'])].plot(
            color=gdf[~gdf['State'].isin(['Alaska', 'Hawaii'])]['plot_color'],
            legend=False,
            linewidth=0.8,
            ax=ax,
            edgecolor='0.8'
        )
        ax.set_title(title, fontsize=30)
        ax.set_axis_off()

        # Plot Alaska
        ax_ak = inset_axes(ax, width="25%", height="25%", loc='lower left', borderpad=0)
        gdf[gdf['State'] == 'Alaska'].plot(
            color=gdf[gdf['State'] == 'Alaska']['plot_color'],
            legend=False,
            ax=ax_ak,
            edgecolor='0.8'
        )
        ax_ak.set_axis_off()

        # Plot Hawaii
        ax_hi = inset_axes(
            ax,
            width="100%",
            height="100%",
            loc='lower left',
            bbox_to_anchor=(0.25, 0.1, 0.15, 0.15),
            bbox_transform=ax.transAxes,
            borderpad=0
        )
        gdf[gdf['State'] == 'Hawaii'].plot(
            color=gdf[gdf['State'] == 'Hawaii']['plot_color'],
            legend=False,
            ax=ax_hi,
            edgecolor='0.8'
        )
        ax_hi.set_axis_off()

    # Create a single legend for the figure
    from matplotlib.patches import Patch

    legend_labels = {
        'OR ≥ 1.50': '#034e7b',
        '1.25 < OR < 1.50': '#3690c0',
        'OR ≤ 1.25': '#a6bddb',
        'OR < 1.0': '#fee090',
        'Non-significant': '#d9d9d9',
        'Rural sample size: n < 50': '#969696',
    }

    patches = [Patch(color=color, label=label) for label, color in legend_labels.items()]
    fig.legend(
        handles=patches,
        loc='lower right',
        ncol=1,
        frameon=True,
        fontsize=20,
        bbox_to_anchor=(0.95, 0.02)
    )

    plt.tight_layout(rect=[0, 0.05, 1, 0.95])
    plt.savefig('geo_model_OR_maps_v26.png', dpi=300)
    print("Generated map with OR < 1.0 category: geo_model_OR_maps_v26.png")

    # Print states with OR < 1.0
    print("\nStates with OR < 1.0 by model:")
    for title, or_col, p_col in models:
        gdf['OR'] = pd.to_numeric(gdf[or_col], errors='coerce')
        gdf['p'] = gdf[p_col].apply(parse_p)
        gdf['category'] = gdf.apply(get_or_category, axis=1, q1=1.25, q2=1.5)

        urban_higher = gdf[(gdf['category'] == 'OR < 1.0') & (gdf['State'] != 'Nationwide')]
        if len(urban_higher) > 0:
            print(f"\n{title}:")
            for idx, row in urban_higher.iterrows():
                print(f"  {row['State']}: OR = {row['OR']:.3f}, p = {row['p']:.4f}")
        else:
            print(f"\n{title}: None")


if __name__ == '__main__':
    main()
