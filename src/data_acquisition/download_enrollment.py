"""
Download CMS "Medicare Monthly Enrollment" and filter to state-level annual totals,
for use as the per-100k-beneficiaries normalization denominator.

Unlike the Geography & Service dataset, this one is versioned monthly but each release
contains cumulative history back to 2013 in a single file (state, year, month grain).
So we just grab the latest version and filter locally -- no need to loop over years
via separate API endpoints.

Ran:
    python download_cms_enrollment.py
"""

from pathlib import Path

import pandas as pd
import requests

CATALOG_URL = "https://data.cms.gov/data.json"
TITLE_KEYWORDS = ["Medicare Monthly Enrollment"]

# Match the year range used in download_cms_geography_service.py
YEARS = list(range(2018, 2025))

OUTPUT_DIR = Path("data/raw/medical_enrollment")
PAGE_SIZE = 5000


def find_latest_distribution(title_keywords):
    resp = requests.get(CATALOG_URL, timeout=60)
    resp.raise_for_status()
    catalog = resp.json()

    for dataset in catalog["dataset"]:
        title = dataset.get("title", "")
        if all(k.lower() in title.lower() for k in title_keywords):
            for distro in dataset["distribution"]:
                if distro.get("format") == "API" and distro.get("description") == "latest":
                    return dataset["title"], distro["accessURL"]

    raise ValueError(
        f"No dataset matched {title_keywords}. "
        "Print [d['title'] for d in catalog['dataset']] to find the exact title."
    )


def fetch_state_year_rows(access_url, years, page_size=PAGE_SIZE):
    """
    Pull annual, state-level rows only:
      BENE_GEO_LVL = 'State'  (excludes National and County-level rows)
      MONTH        = 'Year'   (the annual snapshot row, not a monthly one)

    NOTE: verify these exact filter values against a small unfiltered pull first --
    field values are case-sensitive strings and CMS occasionally tweaks them between
    releases. If this returns 0 rows, drop the filters and inspect BENE_GEO_LVL/MONTH
    unique values directly, then adjust.
    """
    rows = []
    offset = 0
    while True:
        params = {
            "filter[BENE_GEO_LVL]": "State",
            "filter[MONTH]": "Year",
            "size": page_size,
            "offset": offset,
        }
        resp = requests.get(access_url, params=params, timeout=120)
        resp.raise_for_status()
        batch = resp.json()
        if not batch:
            break
        rows.extend(batch)
        if len(batch) < page_size:
            break
        offset += page_size

    df = pd.DataFrame(rows)
    if df.empty:
        return df

    if "YEAR" in df.columns:
        df["YEAR"] = df["YEAR"].astype(int)
        df = df[df["YEAR"].isin(years)]

    return df


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    title, access_url = find_latest_distribution(TITLE_KEYWORDS)
    print(f"Matched dataset: {title}")
    print(f"Latest API endpoint: {access_url}\n")

    df = fetch_state_year_rows(access_url, YEARS)

    if df.empty:
        print("No rows returned -- check the filter values noted in fetch_state_year_rows().")
        return

    out_path = OUTPUT_DIR / "cms_enrollment_state_annual_2018_2024.csv"
    df.to_csv(out_path, index=False)
    print(f"Saved {len(df)} rows -> {out_path}")
    print(f"Years present: {sorted(df['YEAR'].unique().tolist())}")


if __name__ == "__main__":
    main()