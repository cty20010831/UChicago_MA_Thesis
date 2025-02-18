"""
This script is used to extract secret keys from CSV files (data) in a specified 
folder and print the worker_id and secret key to terminal.

It is primarily for checking participants' completion code to approve their HIT.
"""

import pandas as pd
import os
import glob
import json
import argparse

parser = argparse.ArgumentParser(
    description="Extract and print secret keys for worker IDs.",
    epilog="""
        Example usage:
        # Process a single batch folder
        python3 scripts/extract_secret_key.py --folder data/raw/batch_1

        # See example usage of this function
        python3 scripts/extract_secret_key.py --help
        """,
        formatter_class=argparse.RawTextHelpFormatter
    )
parser.add_argument("--folder", type=str, required=True, help="Path to the folder containing CSV files.")
args = parser.parse_args()

# Define the folder for data
folder_path = args.folder

print("\nWorker IDs and their Secret Keys:")
print("-" * 50)
print(f"{'Worker ID':<20} {'Secret Key':<30}")
print("-" * 50)

# Walk through each CSV file in the folder
for file in glob.glob(os.path.join(folder_path, "*.csv")):
    # Ignore some "summary" csv files
    if "drawing_labels_narratives" in file or "secret_key" in file:
        continue

    # Read the CSV file into a DataFrame
    df = pd.read_csv(file)

    # Extract amazon worker_id
    worker_id = file.split("/")[3].split(".")[0]

    # Extract secret key
    secret_key = df.loc[df['trial_index'] == 26, "stimulus"].str.extract(r'<b[^>]*>(.*?)</b>').values[0][0]

    # Print in a formatted way
    print(f"{worker_id:<20} {secret_key:<30}")

print("-" * 50)