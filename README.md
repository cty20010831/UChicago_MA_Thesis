# The Art of Positivity in Drawing: Unveiling the Impact of Positive Mood States on Visual Creativity via Deep Learning

This respostory contains proposal, presentation, and final paper for my MA thesis at UChicago. It extends from the [repository](https://github.com/UC-MACS-30200/course-project-cty20010831) for MACS 30200 course I took during 2024 spring quarter, when I  wrote the proposal for this research project.

## Github Repo Navigation

    .
    ├── analysis/                       # Data analysis of pilot or real data
        ├── results/                        # Main analysis results and supplementary analysis results (potentially)
        ├── scripts/                        # Analysis scripts (including submodules to calculate flexbility and originality)
    ├── drawio/                         # Drawio flowcharts and diagrams
    ├── Paper/                          # Sections (components) of final paper
    ├── Proposal/                       # Sections (components) of final proposal
    ├── sample_drawing_AuDrA            # Sample drawings to test the AuDrA model (in original papers)
    ├── screenshots/                    # Screenshots for better concept/framework explanation for presentation
    ├── CITATIONS.cff                   # Let others know how to cite this repository
    ├── README.md                       # README file
    └── references.bib                  # Bibliography database file

## Study Description
### Introduction
This project explores the intricate relationship between mood states and creativity, specifically focusing on how mood activation levels such as happiness and calmness influence creative outputs. By employing advanced deep learning techniques, experimental tasks like the incompleteness drawing task, and narrative analysis methods like Divergent Semantic Integration (DSI), this study aims to quantitatively dissect the creative process into measurable aspects of flexibility and originality.

### Definitions of Key Concepts
- **Mood:** Mood is characterized as diffuse affective states that are not targeted at any particular object. Unlike emotions, which are acute and directed responses, moods are diffuse
and enduring affective states that subtly color our psychological landscape. Mood significantly affects cognition by influencing what we think and the efficiency of our cognitive processes.
- **Flexibility Aspect of Creativity:** In the context of creativity, flexibility refers to the ability to generate diverse solutions to a problem or adapt one’s thinking to encompass a wide range of possible answers. It involves switching between different thought processes and perspectives, crucial for innovative thinking.
- **Originality Aspect of Creativity:** Originality in creativity is defined as the uniqueness and novelty of the ideas or products generated. It reflects an output's deviation from the norm or standard conventions, showcasing unique or unprecedented solutions.

### Theoretical Frameworks
#### Dual Pathway to Creativity Model (De Dreu et al., 2008)
This model suggests that creativity is influenced by two primary pathways: cognitive flexibility and cognitive persistence. Cognitive flexibility facilitates the exploration of a wide array of ideas and is often enhanced by positive mood states, whereas cognitive persistence involves a deeper, more focused engagement on a narrower set of ideas, typically supported by more negative mood states.

#### Multi-Trial Creative Ideation (MTCI) Framework
Developed by Barbot (2018), the MTCI framework is designed to assess the dynamic process of creative ideation over multiple trials. It emphasizes capturing the fluctuations in creative thinking across different stages of the ideation process, allowing for a detailed examination of how creative ideas evolve and culminate into final products.

### Research Questions
1. How do varying levels of positive mood activation affect cognitive flexibility during the creative ideation process?
2. Does cognitive flexibility mediate the relationship between positive mood and the originality of creative outputs?

### Overview of Research Design
To test these questions, the study introduces **a novel task-measurement combination**, which leverages both the versatility of drawing tasks to uncover the cognitive underpinnings of creativity and employing state-of-the-art artificial intelligence techniques. This study aims to capture the nuanced effects of mood on creative processes and, more specifically, the (potential) building effects of positive mood states on thought-action repertoires. By distinguishing positive mood states varying on the activation dimension—happiness (high activation) and calmness (low activation), this study seeks to scrutinize the hypothesized flexibility pathway in the dual pathway to creativity model. 

This study combines the incomplete shape drawing task and narrative-based reflection, following the MTCI framework. Participants are randomly assigned to a high-arousal positive mood, low-arousal positive mood, or neutral control condition using validated film-based mood induction. Each participant then completes three randomized drawing trials, each followed by a narrative description of their thought process.

**Cognitive flexibility** is measured using two computational approaches:
- Compositional Stroke Embedding (CoSE): A generative model that employs a Gaussian Mixture Model (GMM) to predict next-stroke probabilities. It captures flexibility via (1) average entropy and Bhattacharyya distance (indicating sustained exploratory breadth), and (2) inflection proportions (indicating real-time shifts in strategy).
- Divergent Semantic Integration (DSI): A BERT-based semantic model that evaluates the conceptual distance between ideas in narrative responses, offering a complementary linguistic indicator of semantic flexibility.

**Originality** is quantified using AuDrA, an automated drawing assessment model trained on human-rated sketches from the same task environment.

**Mediation analysis** is used to assess whether flexibility mediates the effect of mood on originality. Mood condition is dummy-coded using the neutral group as the reference category, with each flexibility metric evaluated in a parallel mediation framework.

![](drawio/Overview%20of%20Research%20Design_Full.png)

### Experimental design
The experiment is deployed as a web-based platform built in JavaScript using the jsPsych library. The experiment consists of four main components:
1. Mood induction using embedded video stimuli; 
2. Incomplete shape drawing tasks with a built-in drawing interface (sketchpad.js); 
3. Post-task narrative responses to capture ideation processes; 
4. Demographics and control measures (e.g., openness, affectivity, artistic skill).

Participants complete three drawing-narrative cycles, enabling multi-trial analysis. The system records mouse movements, stroke data, and timing information in real time for further analysis.

![](drawio/Experiment%20Timeline.png)

### Data Analysis 
#### Data
Participants were recruited through Amazon Mechanical Turk and compensated $2.00 for the online experiment that takes around 15 to 20 minutes to complete. The study was approved by the University of Chicago Institutional Review Board (IRB) and followed ethical guidelines for online research. After completing the experiment following the experimental design mentioned above, they were provided a random secret code to enter on MTurk for HIT approval (see [extract_secret_key.py](analysis/scripts/extract_secret_key.py)).

#### Data Preprocessing
Following data collection, we extracted and preprocessed drawing labels, narratives, ratings, and demographic information from each batch of data (see [preprocess.py](analysis/scripts/preprocess.py)). The data was stored in a CSV format, with each row representing a participant's response to a specific drawing task. At the same time, we also saved images of participants' incomplete shape drawings in both ndjson (used for later CoSE-derived flexibility measures) and PNG (used for later AuDrA originality ratings) formats using [save_image.py](analysis/scripts/save_image.py). 

To reproduce the analysis above, you need to run the following commands in the terminal. Make sure you are in the `analysis/` folder, and you have installed all the required packages in your environment (see [requirements.txt](analysis/scripts/requirements.txt)). 
```{bash}
# Make sure at `analysis/` folder
cd analysis 

# Process all batch folders inside `data/raw/` directory for preprocessing
python3 scripts/preprocess.py --folder data/raw/ --parent

# Process all batch folders inside `data/raw/` directory to save images
python3 scripts/save_image.py --folder data/raw/ --parent
```

#### Calculating Flexibility and Originality
After data preprocessing, the next step is to derive the flexibility and originality measures for the final statistical analysis. There are in total three git submodules used to calculate these measures. It is recommended to open separate terminal windows for each submodule to run the scripts under separate virtual environments. 

1. **CoSE**: The CoSE submodule is used to calculate the flexibility measures based on the drawing data. It uses a Gaussian Mixture Model (GMM) to predict next-stroke probabilities and captures flexibility via average entropy, Bhattacharyya distance, and inflection proportions. To run the CoSE submodule (please also refer to the [README file](analysis/scripts/CoSE/thesis/README.md) under the CoSE submodule): 

```{bash}
# Make sure at `analysis/scripts/CoSE/thesis` folder
cd analysis/scripts/CoSE/thesis

# Create a virtual environment
conda env create -f environment.yml

# Activate the virtual environment
conda activate cose

# Load each participant's drawing (for all the three groups of drawings) in ndjson
python load_drawings.py

# Convert .ndjson data into the format CoSE expects and store them in tfrecords
python data_preprocessing.py

# Run the CoSE model on the preprocessed data to derive flexibility metrics.
python main.py
```

2. **AuDrA**: The AuDrA submodule is used to calculate the originality measures based on the drawing data. It uses a pre-trained model to assess the originality of the drawings. To run the AuDrA submodule (please also refer to the [README file](analysis/scripts/AuDrA/README.md) under the AuDrA submodule): 

```{bash}
# Make sure at `analysis/scripts/AuDrA` folder
cd analysis/scripts/AuDrA

# Create a virtual environment
conda env create -f audra_environment_cpu.yml

# Activate the virtual environment
conda activate audra_cpu

# Copy drawings from the `analysis/data/drawings/png` directory into the `user_images` directory in this repository
python store_user_images.py

# Runt the main analysis script
python AuDrA_run.py
```

3. **DSI**: The DSI submodule is used to calculate the semantic flexibility measures based on the narrative data. It uses a BERT-based model to evaluate the conceptual distance between ideas in narrative responses. To run the DSI submodule (please also refer to the [README file](analysis/scripts/DSI/README.md) under the DSI submodule): 

```{bash}
# Make sure at `analysis/scripts/DSI` folder
cd analysis/scripts/DSI

# Create a virtual environment
conda env create -f environment.yml

# Activate the virtual environment
conda activate dsi

# Run the main analysi script
python DSI.py
```

#### Statistical Analysis
After calculating these flexibility and originality measures (and storing them in the deignated positions in each submodule), the next step is to merge these results with the preprocessed data and run the final statistical analysis:
```{bash}
# Make sure at `analysis/` folder
cd analysis

# Merge the results from all three submodules with the preprocessed data
python3 scripts/merge_final_data.py
```

Afterwards, it is time to switch to R for the final statistical analysis, including descriptive statistics, correaltional analysis, mediation analysis, and visualization. The R script is located in the `analysis/scripts/` folder. For my own analysis, I used RStudio to run the script and I have `analysis.Rproj` right under the `analysis` folder. You can open the R project file `analysis.Rproj` in RStudio and simply run [main_results.R](analysis/scripts/main_results.R) to reproduce the results. It will save the results under `analysis/main_results/` folder.

### Results
While mood induction effectively altered participants’ self-reported arousal and valence, no significant differences in flexibility or originality were observed across mood conditions. However, correlational and mediation analyses suggested two distinct modes of flexibility: persistent exploratory breadth (average entropy and Bhattacharyya distance), and adaptive switching (inflection proportions of entropy and Bhattacharyya distance and average DSI). Crucially, only these adaptive switching flexibility measures were significantly associated with originality, with inflection-based and semantic integration metrics emerging as robust predictors. Together, these results raised caveats on transient mood manipulations in creativity research, while illuminating the value of process-level, adaptive flexibility as a core mechanism underlying originality. Moreover, it demonstrates the utility of integrating drawing-based tasks with machine learning and NLP to capture the dynamic, cross-modal mechanisms underpinning original thought.

## Acknoledgement
This research project could not be possible without the support of my advisor [Akram Bakkour](https://psychology.uchicago.edu/directory/Akram-Bakkour) and my preceptor [Sabrina Nardin](https://macss.uchicago.edu/directory/Sabrina-Nardin), whose valuable feedback has pushed me forward in refining my research questions, enhancing methodological rigor, and navigating complex data analysis techniques. Their guidance and insights have been instrumental in shaping the direction of this project, from initial conceptualization to execution, and have inspired me to continuously strive for clarity, precision, and depth in my work.
