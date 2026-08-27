"""
Clean the raw CMS files: drop the 81000-81099 rows from each cms_geography_service_<year>.csv. 
Codes 81000-81099 are routine urinalysis tests, not molecular/genomic testing at all.
Addtionally, Drop National rows to keep State-level data only.

Ran:
   python clean_cms_codes.py
"""
import pandas as pd
from pathlib import Path

INPUT_DIR = Path("data/raw/cms")
OUTPUT_DIR = Path("data/processed/cms")

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

for file in INPUT_DIR.glob("cms_geography_service_*.csv"):
    df = pd.read_csv(file)

    # Clean HCPCS codes
    df["HCPCS_Cd"] = df["HCPCS_Cd"].astype(str).str.strip()

    # Remove routine urinalysis codes (81000–81099)
    before_urinalysis = len(df)

    df = df[
        ~df["HCPCS_Cd"].str.match(r"^810\d{2}$")
    ]

    urinalysis_removed = before_urinalysis - len(df)

    # Keep State-level rows only (remove National rows)
    before_national = len(df)

    df = df[
        df["Rndrng_Prvdr_Geo_Lvl"].astype(str).str.strip() == "State"
    ]

    national_removed = before_national - len(df)

    # Save cleaned file
    output_file = OUTPUT_DIR / file.name
    df.to_csv(output_file, index=False)

    print(
        f"{file.name}: "
        f"removed {urinalysis_removed} urinalysis rows, "
        f"removed {national_removed} National rows, "
        f"kept {len(df)} State rows"
    )