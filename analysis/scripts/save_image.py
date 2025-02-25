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

# Define helper functions to draw and save images (strokes -> image)
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

def convert_strokes_to_ndjson(strokes):
    '''
    Convert the strokes to a ndjson file.

    Arguments:
        1) strokes: a list of list of stroke
    '''
    output_list = []
    
    for stroke in strokes:
        x_vals = []
        y_vals = []
        t_vals = []
        
        for point in stroke:
            x_vals.append(point["x"])
            y_vals.append(point["y"])
            t_vals.append(point["t"])
        
        output_list.append([x_vals, y_vals, t_vals])
    
    return output_list

def main(): 
    # Define paths for raw data and for saving png and json data
    raw_data_path = args.folder
    png_directory = os.path.join("data", "drawings/png")
    ndjson_directory = os.path.join("data", "drawings/ndjson")
    os.makedirs(png_directory, exist_ok=True)
    os.makedirs(ndjson_directory, exist_ok=True)

    # Decide whether to process a single batch folder or all batch folders inside a parent directory
    if args.parent: 
        batch_folders = [os.path.join(raw_data_path, batch) for batch in os.listdir(raw_data_path) if os.path.isdir(os.path.join(raw_data_path, batch))]
    else:
        batch_folders = [raw_data_path]

    # Walk through each CSV file in the folder
    for batch_folder in batch_folders:
        # Get batch name from folder path and define path for saving processed data
        batch_name = os.path.basename(batch_folder)
        
        if batch_name == "pilot":
            continue
        
        save_png_path = os.path.join(png_directory, batch_name)
        save_ndjson_path = os.path.join(ndjson_directory, batch_name)

        # Check whether the directory exists (i.e., whether the batch has been processed)
        if os.path.exists(save_png_path) and os.path.exists(save_ndjson_path):
            print(f"Skipping {batch_name} because it has already been processed")
            continue
        else: 
            os.makedirs(save_png_path, exist_ok=True)
            os.makedirs(save_ndjson_path, exist_ok=True)

        # Process each CSV file in the batch folder
        for file in glob.glob(os.path.join(batch_folder, "*.csv")):
            # Read the CSV file into a DataFrame
            df = pd.read_csv(file)
            
            # Extract amazon worker_id
            worker_id = file.split("/")[3].split(".")[0]

            # Extract stroke
            strokes_df = df.loc[df['trial_type'] == "sketchpad"]["strokes"]
            groups = ["A", "B", "C"] # groups of incomplete shapes
            for i, v in enumerate(strokes_df):
                group = groups[i]

                # Draw and save the drawing
                strokes = json.loads(v)

                # Save the image as png
                image = draw_image(strokes)
                image.save(os.path.join(save_png_path, f"{worker_id}_Group_{group}.png"))

                # Save the strokes as ndjson
                strokes_ndjson = convert_strokes_to_ndjson(strokes)
                with open(os.path.join(save_ndjson_path, f"{worker_id}_Group_{group}.ndjson"), "w") as f:
                    ndjson_record = {"worker_id": worker_id, "group": group, "drawing": strokes_ndjson}
                    f.write(json.dumps(ndjson_record) + "\n")
        
        print(f"Finished processing {batch_name}")

if __name__ == "__main__":
    main()