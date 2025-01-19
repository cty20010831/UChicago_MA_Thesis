# Need to think about how to store the preprocessed data (i.e., in what format of file)
# Need to think about what information (columns in the csv file) must be stored 

# Summarize label and narrative
import pandas as pd
import os
import glob
import json
import argparse

parser = argparse.ArgumentParser(description="Extract and preprocess drawing labels and narratives.")
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

    # Extract stimulus information
    stimulus = df.loc[df['trial_type'] == "video-keyboard-response", "stimulus"]
    stimulus_list = stimulus.apply(lambda x: json.loads(x) if isinstance(x, str) and x.startswith('[') else x)
    group = stimulus_list.iloc[0][0].split(".")[0]

    # Iterate through the labels and their corresponding narratives for three Groups of incomplete drawings
    for drawing_group, label_index, narrative_index in zip(["Incomplete_Group_A", "Incomplete_Group_B", "Incomplete_Group_C"], [9, 12, 15], [10, 13, 16]):
        # Extract label
        response_row = df.loc[df['trial_index'] == label_index, "response"]
        if not response_row.empty:
            try:
                label = json.loads(response_row.iloc[0])['Q0'].lower()
            except (json.JSONDecodeError, KeyError, IndexError):
                label = None
        else:
            label = None

        # Extract narrative
        narrative_row = df.loc[df['trial_index'] == narrative_index, "response"]
        if not narrative_row.empty:
            try:
                narrative = json.loads(narrative_row.iloc[0])['narrative_response']
            except (json.JSONDecodeError, KeyError, IndexError):
                narrative = None
        else:
            narrative = None

        # Append each trial as a separate row
        data_list.append({"worker_id": worker_id, "group": group, "drawing_group": drawing_group,"label": label, "narrative": narrative})

# Convert the list into a DataFrame
combined_df = pd.DataFrame(data_list)
combined_df.set_index("worker_id", inplace=True)  # Set worker_id as the index
combined_df.to_csv(os.path.join(folder_path, "drawing_labels_narratives.csv"))

# Example usage
# python3 preprocess.py --folder data/batch_2