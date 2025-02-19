"""
This script extracts and preprocesses drawing labels, narratives, ratings, and demographic information.
"""

import pandas as pd
import os
import glob
import json
import argparse

# Helper functions
def extract_response(response_row):
    """
    Extract response from a response row into a dictionary.
    """
    response_dic = response_row.apply(lambda x: json.loads(x) if isinstance(x, str) else {})
    response = response_dic.values[0]
    
    return response

# Define arguments for argparse
parser = argparse.ArgumentParser(
    description="Extract and preprocess experimental data.",
    epilog="""
        Example usage:
        # Process a single batch folder
        python3 scripts/preprocess.py --folder data/raw/batch_1

        # Process all batch folders inside a parent directory
        python3 scripts/preprocess.py --folder data/raw/ --parent

        # See example usage of this function
        python3 scripts/extract_secret_key.py --help
        """,
        formatter_class=argparse.RawTextHelpFormatter
    )
parser.add_argument("--folder", type=str, required=True, help="Path to the folder of raw data.")
parser.add_argument("--parent", action="store_true", help="If set, process all subfolders inside the given folder.")
args = parser.parse_args()

def main():
    # Define paths for raw and processed data
    raw_data_path = args.folder
    processed_dir = os.path.join("data", "processed")

    # Decide whether to process a single batch folder or all batch folders inside a parent directory
    if args.parent: 
        batch_folders = [os.path.join(raw_data_path, sub) for sub in os.listdir(raw_data_path) if os.path.isdir(os.path.join(raw_data_path, sub))]
    else:
        batch_folders = [raw_data_path]

    for batch_folder in batch_folders:
        # Get batch name from folder path and define path for saving processed data
        batch_name = os.path.basename(batch_folder)
        if batch_name == "pilot":
            continue
        save_path = os.path.join(processed_dir, batch_name)
        os.makedirs(save_path, exist_ok=True)

        # Initialize an empty list to store DataFrames
        data_list = []

        # Walk through each CSV file in the folder
        for file in glob.glob(os.path.join(batch_folder, "*.csv")):
            # Read the CSV file into a DataFrame
            df = pd.read_csv(file)

            # Extract amazon worker_id
            worker_id = file.split("/")[3].split(".")[0]

            # Extract stimulus information
            stimulus = df.loc[df['trial_type'] == "video-keyboard-response", "stimulus"]
            stimulus_list = stimulus.apply(lambda x: json.loads(x) if isinstance(x, str) and x.startswith('[') else x)
            group = stimulus_list.iloc[0][0].split(".")[0]

            # Extract valence and arousal ratings
            valence_arousal_dic = df.loc[df['trial_type'] == "survey-html-form", "response"]
            parsed_valence_arousal = extract_response(valence_arousal_dic)
            valence = int(parsed_valence_arousal.get("valence", None))
            arousal = int(parsed_valence_arousal.get("arousal", None))

            # Extract control variables and demographics data
            # 1) Positive and negative affectivity scores 
            affectivity_dic = df.loc[df['trial_index'] == 18, "response"]
            affectivity = extract_response(affectivity_dic)
            
            # Derive positive and negative affectivity scores
            positive_affectivity_idx = [0, 2, 4, 8, 9, 11, 13, 15, 16, 18]
            negative_affectivity_idx = [1, 3, 5, 6, 7, 10, 12, 14, 17, 19]

            positive_affectivity_score, negative_affectivity_score = 0, 0
            for i, v in affectivity.items():
                if int(i[1:]) in positive_affectivity_idx:
                    positive_affectivity_score += v
                elif int(i[1:]) in negative_affectivity_idx:
                    negative_affectivity_score += v

            # 2) Openness to experiences
            openness_to_experiences_dic = df.loc[df['trial_index'] == 19, "response"]
            openness_to_experiences = extract_response(openness_to_experiences_dic)
            openness_to_experiences_score = openness_to_experiences['Q0'] + (8 -openness_to_experiences['Q1']) # Second item is reversed scored

            # 3) Cognitive flexibility
            cognitive_flexibility_dic = df.loc[df['trial_index'] == 20, "response"]
            cognitive_flexibility = extract_response(cognitive_flexibility_dic)

            cognitive_flexibility_reverse_scoring_idx = [1, 2, 4, 9]

            cognitive_flexibility_score = 0
            for i, v in cognitive_flexibility.items():
                if int(i[1:]) in cognitive_flexibility_reverse_scoring_idx:
                    score = 7 - v
                else:
                    score = v
                cognitive_flexibility_score += score 

            # 4) Self-rated artistic skill
            self_rated_artistic_skill_dic = df.loc[df['trial_index'] == 21, "response"]
            self_rated_artistic_skill = int(extract_response(self_rated_artistic_skill_dic))

            # 5) Age
            age_dic = df.loc[df['trial_index'] == 22, "response"]
            age = int(extract_response(age_dic)['Q0'])

            # 6) Gender
            gender_dic = df.loc[df['trial_index'] == 23, "response"]
            gender = extract_response(gender_dic)['Q0']

            # 7) Education level
            education_level_dic = df.loc[df['trial_index'] == 24, "response"]
            education_level = extract_response(education_level_dic)['Q0']

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
                    
                data_list.append({
                    "worker_id": worker_id, "group": group, 
                    "valence": valence, "arousal": arousal,
                    "positive_affectivity": positive_affectivity_score,
                    "negative_affectivity": negative_affectivity_score,
                    "openness_to_experiences": openness_to_experiences_score,
                    "cognitive_flexibility": cognitive_flexibility_score,
                    "self_rated_artistic_skill": self_rated_artistic_skill,
                    "age": age, "gender": gender, "education_level": education_level,
                    "drawing_group": drawing_group, "label": label, "narrative": narrative,
                })

        # Convert the list into a DataFrame
        combined_df = pd.DataFrame(data_list)
        combined_df.set_index("worker_id", inplace=True)  # Set worker_id as the index
        combined_df.to_csv(os.path.join(save_path, "processed_data.csv"))

        print(f"Processed {batch_name} data saved to {save_path}")

if __name__ == "__main__":
    main()