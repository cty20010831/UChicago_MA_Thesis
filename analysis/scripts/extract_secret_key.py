"""
This script is used to extract secret keys from CSV files (data) in a specified 
folder and save the worker_id and secret key into a new CSV file. 

It is primarily for checking participants' completion code to approve their HIT.
"""

import pandas as pd
import os
import glob
import json
import argparse

parser = argparse.ArgumentParser(
    description="Extract and preprocess drawing labels and narratives.",
    epilog="""
        Example usage:
        # Process a single batch folder
        python3 scripts/extract_secret_key.py --folder data/batch_1

        # See example usage of this function
        python3 scripts/extract_secret_key.py --help
        """,
        formatter_class=argparse.RawTextHelpFormatter
    )
parser.add_argument("--folder", type=str, required=True, help="Path to the folder containing CSV files.")
args = parser.parse_args()

# Define the folder for data
folder_path = args.folder

# Initialize an empty list to store DataFrames
data_list = []

# Walk through each CSV file in the folder
for file in glob.glob(os.path.join(folder_path, "*.csv")):
    # Ignore some "summary" csv files
    if "drawing_labels_narratives" in file or "secret_key" in file:
        continue

    # Read the CSV file into a DataFrame
    df = pd.read_csv(file)

    # Extract amazon worker_id
    worker_id = file.split("/")[2].split(".")[0]

    # Extract secret key
    secret_key = df.loc[df['trial_index'] == 26, "stimulus"].str.extract(r'<b[^>]*>(.*?)</b>').values[0][0]

    data_list.append({"worker_id": worker_id, "secret_key": secret_key})

# Convert the list into a DataFrame
combined_df = pd.DataFrame(data_list)
combined_df.set_index("worker_id", inplace=True)  # Set worker_id as the index
combined_df.to_csv(os.path.join(folder_path, "secret_key.csv"))