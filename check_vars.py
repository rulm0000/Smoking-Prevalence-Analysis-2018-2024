import pandas as pd
import os

data_dir = 'data'
years = range(2018, 2025)
vars_to_check = [
    '_RFSMOK3', 'SMOKE100', 'SMOKDAY2', '_SMOKER3', 
    '_URBSTAT', '_URBNRRL', 'IYEAR', '_AGE_G', 
    'SEX1', 'SEXVAR', '_SEX', '_RACE', '_RACEGR3', 
    'EDUCA', '_EDUCAG', 'MARITAL', 'EMPLOY1', 
    'INCOME2', '_INCOMG', 'INCOME3', '_INCOMG1', 
    'NUMADULT', 'HHADULT', 'CHILDREN', '_CHLDCNT', 
    'MENTHLTH', '_MENT14D', 'DECIDE', 'ADDEPEV2', 'ADDEPEV3', 
    'CHECKUP1', '_STATE', '_LLCPWT', '_STSTR', '_PSU'
]

results = {}

print(f"{'Year':<6} | {'Found':<6} | {'Missing Variables'}")
print("-" * 60)

for year in years:
    file_path = os.path.join(data_dir, f'LLCP{year}.XPT')
    if not os.path.exists(file_path):
        print(f"{year:<6} | {'N/A':<6} | File not found")
        continue
    
    try:
        # Use pandas to read the SAS XPORT file
        df_iter = pd.read_sas(file_path, format='xport', iterator=True)
        first_row = df_iter.get_chunk(1)
        columns = [col.upper() for col in first_row.columns]
        df_iter.close()
        
        found = []
        missing = []
        for v in vars_to_check:
            if v.upper() in columns:
                found.append(v)
            else:
                missing.append(v)
        
        missing_str = ", ".join(missing)
        print(f"{year:<6} | {len(found):<6} | {missing_str}")
        
    except Exception as e:
        print(f"{year:<6} | {'N/A':<6} | Error: {str(e)}")
