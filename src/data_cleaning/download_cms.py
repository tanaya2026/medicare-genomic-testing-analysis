"""
Download CMS "Medicare Physician & Other Practitioners - by Geography and Service"
for multiple years, filtered to genomic/molecular pathology CPT codes (81xxx range).

Docs this is based on: CMS "API FAQ for data.CMS.gov", v1.6 (Oct 2024)
https://data.cms.gov/sites/default/files/2024-10/.../API%20Guide%20Formatted%201_6.pdf

Approach:
  1. Fetch the catalog at https://data.cms.gov/data.json (never hardcode dataset UUIDs —
     CMS explicitly recommends always resolving through the catalog).
  2. Find the dataset whose title matches this file, and read its `distribution` array.
     Each entry with format == "API" has a `temporal` field ("YYYY-01-01/YYYY-12-31")
     giving you that year's dedicated API endpoint.
  3. For each year you want, paginate through that year's endpoint (5,000 rows/page max),
     filtering server-side on HCPCS_Cd STARTS_WITH your CPT prefix(es), so you never
     pull down the full multi-million-row file.

Ran:
    python download_cms.py
"""

import time
from pathlib import Path

import pandas as pd
import requests

CATALOG_URL = "https://data.cms.gov/data.json"

# Fuzzy title match -- all of these substrings must appear (case-insensitive) in the
# dataset title. Adjust if CMS renames the dataset.
TITLE_KEYWORDS = ["Physician", "Geography and Service"]

# CPT/HCPCS prefixes to keep. 81xxx = molecular pathology / genomic sequencing / MAAA.
# Add "87" here later only if you deliberately expand into infectious-disease molecular codes.
CPT_PREFIXES = ["81"]

# Years to pull. CMS utilization trend can go back further than the CDC cancer data
# (which currently tops out at 2022) -- pull the wider CMS window here, and just be
# explicit in your writeup that the access-gap comparison is limited to years where
# both datasets overlap.
YEARS = list(range(2018, 2025))  # 2018-2024 inclusive

OUTPUT_DIR = Path("data/raw/cms")
PAGE_SIZE = 5000


def find_dataset_distributions(title_keywords):
    resp = requests.get(CATALOG_URL, timeout=60)
    resp.raise_for_status()
    catalog = resp.json()

    matches = []
    for dataset in catalog["dataset"]:
        title = dataset.get("title", "")
        if all(k.lower() in title.lower() for k in title_keywords):
            matches.append(dataset)

    if not matches:
        raise ValueError(
            f"No dataset matched {title_keywords}. "
            "Print [d['title'] for d in catalog['dataset']] to find the exact title."
        )
    if len(matches) > 1:
        print("WARNING: multiple datasets matched, using the first:")
        for m in matches:
            print(f"  - {m['title']}")

    chosen = matches[0]
    return chosen["title"], chosen["distribution"]


def year_from_temporal(temporal):
    # temporal looks like "2022-01-01/2022-12-31"
    if not temporal:
        return None
    start = temporal.split("/")[0]
    try:
        return int(start[:4])
    except ValueError:
        return None


def fetch_year_rows(access_url, cpt_prefix, page_size=PAGE_SIZE):
    """Paginate through one year's API endpoint, filtered to one HCPCS prefix."""
    rows = []
    offset = 0
    while True:
        params = {
            "filter[condition][path]": "HCPCS_Cd",
            "filter[condition][operator]": "STARTS_WITH",
            "filter[condition][value]": cpt_prefix,
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
        time.sleep(0.2)  # be polite to the API
    return rows


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    title, distributions = find_dataset_distributions(TITLE_KEYWORDS)
    print(f"Matched dataset: {title}\n")

    api_versions = {}
    for d in distributions:
        if d.get("format") == "API":
            yr = year_from_temporal(d.get("temporal"))
            if yr:
                api_versions[yr] = d["accessURL"]

    print(f"Years available via API: {sorted(api_versions.keys())}\n")

    for year in YEARS:
        if year not in api_versions:
            print(f"[skip] {year}: not available as a separate API version")
            continue

        access_url = api_versions[year]
        print(f"[fetch] {year} <- {access_url}")

        all_rows = []
        for prefix in CPT_PREFIXES:
            rows = fetch_year_rows(access_url, prefix)
            print(f"    prefix '{prefix}': {len(rows)} rows")
            all_rows.extend(rows)

        if not all_rows:
            print(f"    no rows returned for {year}, skipping save")
            continue

        df = pd.DataFrame(all_rows)
        out_path = OUTPUT_DIR / f"cms_geography_service_{year}.csv"
        df.to_csv(out_path, index=False)
        print(f"    saved {len(df)} rows -> {out_path}\n")


if __name__ == "__main__":
    main()