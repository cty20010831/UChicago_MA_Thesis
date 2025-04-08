# This script is in charge of some exploratory mediation (potentially included
# in the exploratory/supplementary sections of the paper). 

# -------------------------------------------------------------------------
# Load the helper function
source("scripts/mediation_helper_functions.R")

# Load packages used 
if (!requireNamespace("tidyverse", quietly = TRUE)) install.packages("tidyverse")
library(tidyverse)

# -------------------------------------------------------------------------
# Define constants
# Note, the R project (Rproj) is set under "analysis/"
merged_data_path = "results/merged_data/merged_data_filtered.csv" 

potential_mediators = c(
  "avg_entropy", "avg_bhatt_dist", 
  "inflection_prop_entropy", "inflection_prop_bhatt",
  "DSI")

control_cols = c(
  "positive_affectivity", "negative_affectivity", "openness_to_experiences", 
  "cognitive_flexibility", "self_rated_artistic_skill"
)

# -------------------------------------------------------------------------
# Load and preprocess the data
merged_data = read.csv(merged_data_path)

# Define dummy variables
merged_data$D1 <- ifelse(merged_data$group == "positive_valence_high_arousal", 1, 0)
merged_data$D2 <- ifelse(merged_data$group == "positive_valence_low_arousal", 1, 0)

# Aggregate to one row per participant
agg_data <- merged_data %>%
  group_by(batch_name, worker_id) %>%
  summarise(
    D1 = first(D1),
    D2 = first(D2),
    group = first(group),
    avg_entropy = mean(avg_entropy, na.rm = TRUE),
    avg_bhatt_dist = mean(avg_bhatt_dist, na.rm = TRUE),
    inflection_prop_entropy = mean(inflection_prop_entropy, na.rm = TRUE),
    inflection_prop_bhatt = mean(inflection_prop_bhatt, na.rm = TRUE),
    DSI = mean(DSI, na.rm = TRUE),
    AuDrA = mean(AuDrA, na.rm = TRUE),
    valence = first(valence),
    arousal = first(arousal),
    positive_affectivity = first(positive_affectivity),
    negative_affectivity = first(negative_affectivity),
    openness_to_experiences = first(openness_to_experiences),
    cognitive_flexibility = first(cognitive_flexibility),
    self_rated_artistic_skill = first(self_rated_artistic_skill)
  )


# -------------------------------------------------------------------------
# Perform mediation analysis (positive, high arousal versus  positive, low arousal)

# Filter only high and low arousal groups
hl_data <- agg_data %>%
  filter(D1 + D2 == 1)

# Create new dummy variable for high vs. low
hl_data$D_high_vs_low <- ifelse(hl_data$D1 == 1, 1, 0)
fits <- single_level_mediation(data=hl_data, 
                               treatment_vars="D_high_vs_low", 
                               mediator_cols=potential_mediators)

# -------------------------------------------------------------------------
# Multi-level mediation
# -------------------------------------------------------------------------
# Define the "id" column for multi-level mediation
merged_data$id = paste(merged_data$batch_name, merged_data$worker_id)

# -------------------------------------------------------------------------
# Perform mediation analysis (arousal as IV)
fits <- multilevel_mediation(
  data=merged_data, 
  id_col="id", 
  treatment_vars="arousal",
  mediator_cols=potential_mediators
)

# Filter only high and low arousal groups
hl_data_multilevel <- merged_data[
  merged_data$group == "positive_valence_high_arousal" |
    merged_data$group == "positive_valence_low_arousal", 
]

# Create new dummy variable for high vs. low
hl_data_multilevel$D_high_vs_low <- ifelse(hl_data_multilevel$group == "positive_valence_high_arousal", 1, 0)

# -------------------------------------------------------------------------
# Perform mediation analysis (arousal as IV & only high and low arousal groups)
fits <- multilevel_mediation(
  data=hl_data_multilevel, 
  id_col="id", 
  treatment_vars="arousal",
  mediator_cols=potential_mediators
)