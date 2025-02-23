from PIL import Image, ImageDraw
import os
import glob
import json
import pandas as pd
import argparse

# Define arguments for argparse
parser = argparse.ArgumentParser(
    description="Save images of participants' incomplete shape drawings.",
    epilog="""
        Example usage:
        # Process a single batch folder
        python3 scripts/save_image.py --folder data/raw/batch_1

        # Process all batch folders inside a parent directory
        python3 scripts/save_image.py --folder data/raw/ --parent

        # See example usage of this function
        python3 scripts/save_image.py --help
        """,
        formatter_class=argparse.RawTextHelpFormatter
    )
parser.add_argument("--folder", type=str, required=True, help="Path to the folder of raw data.")
parser.add_argument("--parent", action="store_true", help="If set, process all subfolders inside the given folder.")
args = parser.parse_args()

def draw_image(strokes):
    '''
    Draw and save the image based on given x, y coordinates and actions.

    Arguments:
        1) strokes: a list of list of stroke
    '''

    # Initialize a blank grayscale canvas
    canvas_size = (400, 400)
    image = Image.new("L", canvas_size, "white")  # "L" mode for grayscale
    draw = ImageDraw.Draw(image)

    # Process each stroke and draw them
    for stroke in strokes:
        current_path = []
        for point in stroke:
            x, y, action = point["x"], point["y"], point["action"]
            if action == "start":
                current_path = [(x, y)]  # Start a new path
            elif action == "move":
                current_path.append((x, y))  # Add points to the current path
            elif action == "end":
                current_path.append((x, y))  # Complete the stroke
                draw.line(current_path, fill=0, width=2)  # 0 is black in grayscale
                current_path = []  # Reset for the next stroke

    # Return the image
    return image

def main(): 
    # Define paths for raw and processed data
    raw_data_path = args.folder
    drawing_directory = os.path.join("data", "drawings/png")
    os.makedirs(drawing_directory, exist_ok=True)

    # Decide whether to process a single batch folder or all batch folders inside a parent directory
    if args.parent: 
        batch_folders = [os.path.join(raw_data_path, sub) for sub in os.listdir(raw_data_path) if os.path.isdir(os.path.join(raw_data_path, sub))]
    else:
        batch_folders = [raw_data_path]

    # Walk through each CSV file in the folder
    for batch_folder in batch_folders:
        # Get batch name from folder path and define path for saving processed data
        batch_name = os.path.basename(batch_folder)
        
        if batch_name == "pilot":
            continue
        save_path = os.path.join(drawing_directory, batch_name)

        # Check whether the directory exists (i.e., whether the batch has been processed)
        if os.path.exists(save_path):
            print(f"Skipping {batch_name} because it has already been processed")
            continue
        else: 
            os.makedirs(save_path)

        # Process each CSV file in the batch folder
        for file in glob.glob(os.path.join(batch_folder, "*.csv")):
            # Read the CSV file into a DataFrame
            df = pd.read_csv(file)
            
            # Extract amazon worker_id
            worker_id = file.split("/")[3].split(".")[0]

            # Extract stroke
            strokes_df = df.loc[df['trial_type'] == "sketchpad"]["strokes"]
            groups = ["A", "B,", "C"] # groups of incomplete shapes
            for i, v in enumerate(strokes_df):
                group = groups[i]

                # Draw and save the drawing
                strokes = json.loads(v)
                image = draw_image(strokes)
                image.save(os.path.join(save_path, f"{worker_id}_Group_{group}.png"))
        
        print(f"Finished processing {batch_name}")

if __name__ == "__main__":
    main()