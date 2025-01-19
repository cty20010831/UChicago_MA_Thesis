from PIL import Image, ImageDraw
import os
import glob
import json
import pandas as pd
import argparse

parser = argparse.ArgumentParser(description="Extract and preprocess drawing labels and narratives.")
parser.add_argument("--folder", type=str, required=True, help="Path to the folder containing CSV files.")
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
    # Define the folder for data
    folder_path = args.folder

    # Create a directory to store images of participants' strokes (if not existed)
    drawing_directory = os.path.join(folder_path, "drawings")
    os.makedirs(drawing_directory, exist_ok=True)

    # Walk through each CSV file in the folder
    for file in glob.glob(os.path.join(folder_path, "*.csv")):
        # Ignore some "summary" csv files
        if "drawing_labels_narratives" in file or "secret_key" in file:
            continue
        
        # Read the CSV file into a DataFrame
        df = pd.read_csv(file)
        
        # Extract amazon worker_id
        worker_id = file.split("/")[2].split(".")[0]

        # Extract stroke
        strokes_df = df.loc[df['trial_type'] == "sketchpad"]["strokes"]
        groups = ["A", "B,", "C"] # groups of incomplete shapes
        for i, v in enumerate(strokes_df):
            group = groups[i]

            # Draw and save the drawing
            strokes = json.loads(v)
            image = draw_image(strokes)
            image.save(os.path.join(drawing_directory, f"{worker_id}_Group_{group}.png"))

if __name__ == "__main__":
    main()

# Example usage
# python3 save_image.py --folder data/batch_2