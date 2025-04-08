"""
This script is used to merge the output of CoSE, DSI, and AuDrA with the processed data (mood states and questionnaire responses).
"""
import os
import pandas as pd

# Previously, I thought about excluding participants based on the following criteria:
# 1) Participants who had (at least two) same response of narrative text for three groups of drawings;
# 2) Participants who merely give the label instead of recollecting their thought processes.
# E.g.,
# EXCLUDE_BATCH_WORKER_IDS = {
#     "batch_1_A1CTM8W6WOP9Z6", "batch_1_A1GWFF5651XU8", "batch_1_A1XC0NLK25A2NR", 
#     "batch_1_A2WPFFUE15XC92", "batch_1_A2Y7L7R5UTQ5R2", "batch_1_A3DZYQFQBQKZZL",
#     "batch_1_A313QTGC8AQY8V", "batch_1_AO5YCQ02AM51P",
#     "batch_2_A1CTM8W6WOP9Z6", "batch_2_A1GWFF5651XU8", "batch_2_A1UP5HLWPM1LAC", 
#     "batch_2_A1V1RJ47RN1PIN", "batch_2_A2LS5LMPAUJYWF", "batch_2_A3V5AU4PA8H6W6", 
#     "batch_2_A12N0FC67RN8AH", "batch_2_A17C3DY9IF0FG8", "batch_2_A313QTGC8AQY8V", 
#     "batch_2_A393VRSHKTX14M", "batch_2_AWMVGCVTHV6HG",
#     "batch_3_A1CTM8W6WOP9Z6", "batch_3_A1GWFF5651XU8", "batch_3_A1UP5HLWPM1LAC",
#     "batch_3_A2J1GZV49A449H", "batch_3_A2JOOL8E15ZWZ9", "batch_3_A2LS5LMPAUJYWF",
#     "batch_3_A2WHV7G2VTDHDN", "batch_3_A3SEMI0DRRHRK", "batch_3_A313QTGC8AQY8V"
# }

EXCLUDE_BATCH_WORKER_IDS = {}

def main():
    # # # # # # # # 
    # Save or load aggregated (merged) data
    # # # # # # # # 
    merged_df_path = "results/merged_data/merged_data_full.csv"
    # Read CoSE, DSI, and AuDrA output
    cose_df = pd.read_csv("scripts/CoSE/thesis/CoSE_output.csv")
    dsi_df = pd.read_csv("scripts/DSI/output/DSI_output.csv")
    audra_df = pd.read_csv("scripts/AuDrA/AuDrA_predictions.csv")

    # Merge thesse three dataframes (based on worker_id and drawing_group)
    merged_df = pd.merge(cose_df, dsi_df, on=["batch_name", "worker_id", "drawing_group"], how="inner")
    merged_df = pd.merge(merged_df, audra_df, on=["batch_name", "worker_id", "drawing_group"], how="inner")

    # Load preprocessd data to get mood states and questionnaire responses
    processed_dir = "data/processed"
    processed_df_list = []
    for i in os.listdir(processed_dir):
        if i == ".DS_Store":
            continue
        df = pd.read_csv(os.path.join(processed_dir, i, "processed_data.csv"))
        # Add batch_name to the dataframe
        df.insert(0, "batch_name", i)
        processed_df_list.append(df)
    
    processed_df = pd.concat(processed_df_list, ignore_index=True)
    
    # Merge the merged_df with processed_df
    merged_df = pd.merge(processed_df, merged_df, on=["batch_name", "worker_id", "drawing_group"], how="inner")

    # Save the merged_df
    merged_df.to_csv(merged_df_path, index=False)

    # # # # # # # # 
    # Data Wrangling
    # # # # # # # # 
    # Exclude participants based on criteria
    merged_df["batch_worker_id"] = merged_df["batch_name"] + "_" + merged_df["worker_id"]
    merged_df_filtered = merged_df[~merged_df["batch_worker_id"].isin(EXCLUDE_BATCH_WORKER_IDS)]
    merged_df_filtered = merged_df_filtered.drop(columns=["batch_worker_id"])

    # Reorder the dataframe based on the batch_name
    merged_df_filtered = merged_df_filtered.sort_values(by=["batch_name", "worker_id", "drawing_group"])

    # # Select the first drawing for each participant
    # merged_df_filtered = merged_df_filtered.groupby(["batch_name", "worker_id"], as_index=False).first()

    # Save the filtered dataframe
    filtered_df_path = "results/merged_data/merged_data_filtered.csv"
    merged_df_filtered.to_csv(filtered_df_path, index=False)

if __name__ == "__main__":
    main()

# Example usage:
# python3 scripts/merge_final_data.py