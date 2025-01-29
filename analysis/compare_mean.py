import pandas as pd
import os
import glob
import json
import argparse

# Setup argparse with the new --parent argument
parser = argparse.ArgumentParser(
    description="Compare average valence and arousal rating for three mood induction groups.",
    epilog="""
        Example usage:
        # Process a single batch folder
        python3 compare_mean.py --folder data/batch_1

        # Process all batch folders inside a parent directory
        python3 compare_mean.py --folder data/ --parent

        # See example usage of this function
        python3 compare_mean.py --help
        """,
        formatter_class=argparse.RawTextHelpFormatter
    )
parser.add_argument("--folder", type=str, required=True, help="Path to a batch folder or parent folder containing batch folders.")
parser.add_argument("--parent", action="store_true", help="If set, process all subfolders inside the given folder.")

args = parser.parse_args()

def process_folder(folder_path, is_parent=False):
    """
    Process either a single batch folder or a parent folder containing multiple batch folders.
    
    Args:
        folder_path (str): Path to either a single batch folder or a parent folder.
        is_parent (bool): Whether the input is a parent folder with multiple batch subfolders.
        
    Returns:
        pd.DataFrame: Aggregated DataFrame containing valence and arousal means.
    """
    dfs = []  # List to store data from all processed files

    # Determine batch folders to process
    if is_parent:
        batch_folders = [os.path.join(folder_path, sub) for sub in os.listdir(folder_path) if os.path.isdir(os.path.join(folder_path, sub))]
    else:
        batch_folders = [folder_path]  # Treat as a single batch folder

    # Process each batch folder
    for batch_folder in batch_folders:
        batch_name = os.path.basename(batch_folder)  # Extract batch folder name

        # Ignore pilot data
        if batch_name == "pilot":
            continue

        for file in glob.glob(os.path.join(batch_folder, "*.csv")):
            # Ignore "summary" CSV files
            if "drawing_labels_narratives" in file or "secret_key" in file:
                continue

            # Read the CSV file into a DataFrame
            df = pd.read_csv(file)

            # Validate data
            if (df.loc[df['trial_type'] == "video-keyboard-response", "trial_index"] == 3).all():
                # Extract stimulus information
                stimulus = df.loc[df['trial_type'] == "video-keyboard-response", "stimulus"]
                stimulus_list = stimulus.apply(lambda x: json.loads(x) if isinstance(x, str) and x.startswith('[') else x)
                group = stimulus_list.iloc[0][0].split(".")[0]

                # Extract response as a dictionary (valence and arousal)
                valence_arousal_dic = df.loc[df['trial_type'] == "survey-html-form", "response"]
                parsed_responses = valence_arousal_dic.apply(lambda x: json.loads(x) if isinstance(x, str) else {})

                # Add batch folder and group (stimulus) to each parsed response
                parsed_data = [
                    {
                        "batch": batch_name,  # Track which batch the data comes from
                        "group": group,
                        "valence": int(response.get("valence", None)),
                        "arousal": int(response.get("arousal", None))
                    }
                    for response in parsed_responses
                ]

                # Store relevant information for further analysis
                dfs.append(pd.DataFrame(parsed_data))

    # Combine all DataFrames into one
    if not dfs:
        print("No valid data found.")
        return None

    combined_df = pd.concat(dfs, ignore_index=True)

    # Compute group size
    group_sizes = combined_df['group'].value_counts().reset_index()
    group_sizes.columns = ['group', 'group_size']

    # Merge group size information
    combined_df = combined_df.merge(group_sizes, on='group', how='left')

    # Aggregate means across groups and batches
    aggregated_means = combined_df.groupby(['group', 'group_size'])[['valence', 'arousal']].mean()
    
    return aggregated_means

# Run the function with the argparse arguments
aggregated_results = process_folder(args.folder, is_parent=args.parent)

# Print aggregated means
if aggregated_results is not None:
    print("Aggregated Mean Valence and Arousal:")
    print(aggregated_results)


# 