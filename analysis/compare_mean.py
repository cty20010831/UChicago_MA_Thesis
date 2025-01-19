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
dfs = []

# Walk through each CSV file in the folder
for file in glob.glob(os.path.join(folder_path, "*.csv")):
    # Ignore some "summary" csv files
    if "drawing_labels_narratives" in file or "secret_key" in file:
        continue

    # Read the CSV file into a DataFrame
    df = pd.read_csv(file)

    # Make sure it is valid data 
    if (df.loc[df['trial_type'] == "video-keyboard-response", "trial_index"] == 3).all():
        # Extract stimulus information
        stimulus = df.loc[df['trial_type'] == "video-keyboard-response", "stimulus"]
        stimulus_list = stimulus.apply(lambda x: json.loads(x) if isinstance(x, str) and x.startswith('[') else x)
        group = stimulus_list.iloc[0][0].split(".")[0]

        # Extract response as a dictionary (valence and arousal)
        valence_arousal_dic = df.loc[df['trial_type'] == "survey-html-form", "response"]
        parsed_responses = valence_arousal_dic.apply(lambda x: json.loads(x) if isinstance(x, str) else {})

        # Add group (stimulus) to each parsed response
        parsed_data = [
            {
                "group": group,
                "valence": int(response.get("valence", None)),
                "arousal": int(response.get("arousal", None))
            }
            for response in parsed_responses
        ]

        # Store relevant information for further analysis
        dfs.append(pd.DataFrame(parsed_data))

# Combine all DataFrames into one
combined_df = pd.concat(dfs, ignore_index=True)

# Perform mean comparison by stimulus (mood induction group)
# Note: valence is from -4 to 4 whereas arousal is from 1 to 9 
print(combined_df.groupby('group')[['valence', 'arousal']].mean())

# Example usage
# python3 compare_mean.py --folder data/batch_2