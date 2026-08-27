"""
Combine all 7 CMS files into one 2018-2024 csv file to generate PivotTables in Excel.

Ran:
   python combine_cms_files.py
"""
import pandas as pd
from pathlib import Path

INPUT_DIR = Path("data/processed/cms")
OUTPUT_FILE = Path("data/processed/cms_2018_2024_combined.xlsx")

files = sorted(INPUT_DIR.glob("cms_geography_service_*.csv"))

dfs = []

for file in files:
    df = pd.read_csv(file)

    # Extract year from filename
    year = file.stem.split("_")[-1]
    df["Year"] = int(year)

    dfs.append(df)

combined = pd.concat(dfs, ignore_index=True)

combined.to_excel(OUTPUT_FILE, index=False)

print(f"Combined {len(files)} files")
print(f"Total rows: {len(combined)}")
print(f"Saved to: {OUTPUT_FILE}")