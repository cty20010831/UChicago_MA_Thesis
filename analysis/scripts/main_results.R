# This R script serves to produce the results and plot figures in the final 
# thesis (paper).

merged_data_path = "results/merged_data/merged_data_filtered.csv" 

# Output directories
main_results_dir = "results/main_results/"
dir.create(main_results_dir, recursive = TRUE, showWarnings = FALSE)

mediators = c(
  "avg_entropy", "avg_bhatt_dist", 
  "inflection_prop_entropy", "inflection_prop_bhatt",
  "DSI")

control_cols = c(
  "positive_affectivity", "negative_affectivity", "openness_to_experiences", 
  "cognitive_flexibility", "self_rated_artistic_skill"
)

# -------------------------------------------------------------------------
# Load and preprocess the data
if (!requireNamespace("tidyverse", quietly = TRUE)) install.packages("tidyverse")
library(tidyverse)

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
    self_rated_artistic_skill = first(self_rated_artistic_skill),
    .groups = "drop"
  )

# Rename values of "group" variable
agg_data$group <- recode(agg_data$group,
                         "positive_valence_high_arousal" = "Positive Valence & High Arousal Group",
                         "positive_valence_low_arousal"  = "Positive Valence & Low Arousal Group",
                         "neutral" = "Neutral Group"
)

# -------------------------------------------------------------------------
# 1. Demographics
demographics_dir <- file.path(main_results_dir, "demographics/")
dir.create(demographics_dir, recursive = TRUE, showWarnings = FALSE)
demo_summary_path <- file.path(demographics_dir, "demographics_summary.txt")

sink(demo_summary_path)

cat("===== Demographic Summary =====\n\n")

# Age summary
age_data <- merged_data %>%
  group_by(batch_name, worker_id) %>%
  summarise(age = first(age), .groups = "drop") %>%
  filter(!is.na(age))

age_N <- nrow(age_data)
age_min <- min(age_data$age)
age_max <- max(age_data$age)
age_mean <- round(mean(age_data$age), 1)
age_sd <- round(sd(age_data$age), 1)

cat(sprintf("Age range: %d to %d (M = %.1f, SD = %.1f)\n\n", age_min, age_max, age_mean, age_sd))


# Gender summary
gender_summary <- merged_data %>%
  group_by(batch_name, worker_id) %>%
  summarise(gender = first(gender), .groups = "drop") %>%
  count(gender) %>%
  mutate(percent = round(100 * n / sum(n), 1))

cat("Gender distribution:\n")
for (i in 1:nrow(gender_summary)) {
  cat(sprintf("- %s: %d (%.1f%%)\n", gender_summary$gender[i], gender_summary$n[i], gender_summary$percent[i]))
}
cat("\n")

# Education summary
ed_summary <- merged_data %>%
  group_by(batch_name, worker_id) %>%
  summarise(education = first(education_level), .groups = "drop")

ed_counts <- ed_summary %>%
  count(education) %>%
  mutate(percent = round(100 * n / sum(n), 1))

cat("Education levels:\n")
for (i in 1:nrow(ed_counts)) {
  cat(sprintf("- %s: %d (%.1f%%)\n", ed_counts$education[i], ed_counts$n[i], ed_counts$percent[i]))
}

higher_ed <- ed_summary %>%
  filter(education %in% c("Bachelor degree", "Graduate degree (Master, Doctorate)")) %>%
  summarise(N = n()) %>%
  pull(N)

percent_higher <- round(100 * higher_ed / nrow(ed_summary), 1)
cat(sprintf("\nPercentage with bachelor's degree or higher: %.1f%%\n", percent_higher))

sink()

# -------------------------------------------------------------------------
# 2. Mood Induction Check (Manipulation Check)
# One-way ANOVA or t-tests for arousal (with post-hoc tests if needed).
# Boxplot of arousal by condition (probably include valence as well)

mood_induction_check_dir <- paste0(main_results_dir, "mood_induction_check/")
dir.create(mood_induction_check_dir, recursive = TRUE, showWarnings = FALSE)

# Load packages
if (!requireNamespace("ggplot2", quietly = TRUE)) install.packages("ggplot2")
if (!requireNamespace("ggpubr", quietly = TRUE)) install.packages("ggpubr")
if (!requireNamespace("viridis", quietly = TRUE)) install.packages("viridis")
if (!requireNamespace("ggbeeswarm", quietly = TRUE)) install.packages("ggbeeswarm")
if (!requireNamespace("withr", quietly = TRUE)) install.packages("ggbeeswarm")
if (!requireNamespace("emmeans", quietly = TRUE)) install.packages("emmeans")
if (!requireNamespace("effectsize", quietly = TRUE)) install.packages("effectsize")
library(ggplot2)
library(ggpubr)
library(viridis)
library(ggbeeswarm)
library(emmeans)
library(effectsize)

# Run ANOVAs
anova_arousal <- aov(arousal ~ group, data = agg_data)
anova_valence <- aov(valence ~ group, data = agg_data)

# Run post-hoc tests
tukey_arousal <- emmeans(anova_arousal, pairwise ~ group)
tukey_valence <- emmeans(anova_valence, pairwise ~ group)

# Save arousal summary
sink(file.path(mood_induction_check_dir, "anova_arousal_summary.txt"))
cat("===== ANOVA for Arousal by Group =====\n\n")
print(summary(anova_arousal))
cat("\nEffect size (η²):\n")
print(eta_squared(anova_arousal))
cat("\nPost-hoc Tukey Test:\n")
print(tukey_arousal$contrasts)
sink()

# Save valence summary
sink(file.path(mood_induction_check_dir, "anova_valence_summary.txt"))
cat("===== ANOVA for Valence by Group =====\n\n")
print(summary(anova_valence))
cat("\nEffect size (η²):\n")
print(eta_squared(anova_valence))
cat("\nPost-hoc Tukey Test:\n")
print(tukey_valence$contrasts)
sink()

# Shared plot style
box_plot_style <- theme_minimal(base_size = 14) +
  theme(
    legend.position = "none",
    plot.title = element_text(hjust = 0.5),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

# Define group comparisons
comparisons <- list(
  c("Neutral Group", "Positive Valence & Low Arousal Group"),
  c("Neutral Group", "Positive Valence & High Arousal Group"),
  c("Positive Valence & Low Arousal Group", "Positive Valence & High Arousal Group")
)

# Arousal Plot
png(file.path(mood_induction_check_dir, "arousal_by_group.png"), width = 1000, height = 700)
ggplot(agg_data, aes(x = group, y = arousal, fill = group, color = group)) +
  geom_boxplot(outlier.shape = NA, alpha = 0.5, width = 0.6) +
  geom_jitter(width = 0.15, alpha = 0.8, shape = 21, size = 2) +
  scale_fill_viridis_d(option = "D") +
  scale_color_viridis_d(option = "D") +
  labs(
    title = "Arousal Ratings by Mood Group",
    x = "Mood Group",
    y = "Arousal (1 to 9)"
  ) +
  ggpubr::stat_compare_means(comparisons = comparisons, method = "t.test", label = "p.signif") +
  box_plot_style
dev.off()

# Valence Plot
png(file.path(mood_induction_check_dir, "valence_by_group.png"), width = 1000, height = 700)
ggplot(agg_data, aes(x = group, y = valence, fill = group, color = group)) +
  geom_boxplot(outlier.shape = NA, alpha = 0.5, width = 0.6) +
  geom_jitter(width = 0.15, alpha = 0.8, shape = 21, size = 2) +
  scale_fill_viridis_d(option = "D") +
  scale_color_viridis_d(option = "D") +
  labs(
    title = "Valence Ratings by Mood Group",
    x = "Mood Group",
    y = "Valence (-4 to +4)"
  ) +
  ggpubr::stat_compare_means(comparisons = comparisons, method = "t.test", label = "p.signif") +
  box_plot_style
dev.off()

# -------------------------------------------------------------------------
# 3. Descriptive Statistics
# -------------------------------------------------------------------------
# 3a. Get descriptive statistics by condition
# Output directory
descriptive_stats_dir <- file.path(main_results_dir, "descriptive_stats/")
dir.create(descriptive_stats_dir, recursive = TRUE, showWarnings = FALSE)

# Variables to include
vars_to_plot <- c(mediators, "AuDrA")

# Compute mean and SD per group
desc_stats_long <- agg_data %>%
  dplyr::select(group, all_of(vars_to_plot)) %>%
  pivot_longer(-group, names_to = "measure", values_to = "value") %>%
  group_by(group, measure) %>%
  summarise(
    mean = mean(value, na.rm = TRUE),
    sd   = sd(value, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(formatted = sprintf("%.2f (%.2f)", mean, sd))

# Reshape to wide format (groups as columns)
desc_stats_wide <- desc_stats_long %>%
  dplyr::select(measure, group, formatted) %>%
  pivot_wider(names_from = group, values_from = formatted)

# Save to .txt
sink(file.path(descriptive_stats_dir, "groupwise_descriptive_stats.txt"))
cat("===== Descriptive Statistics by Group (M (SD)) =====\n\n")
print(as.data.frame(desc_stats_wide), row.names = FALSE)
sink()

# -------------------------------------------------------------------------
# 3b. Run one-way ANOVAs for each variable by mood group
if (!requireNamespace("effectsize", quietly = TRUE)) install.packages("effectsize")
library(effectsize)

anova_results <- lapply(vars_to_plot, function(var) {
  formula <- as.formula(paste(var, "~ group"))
  aov_model <- aov(formula, data = agg_data)
  summary_out <- summary(aov_model)
  
  # Extract F value, p value, degrees of freedom
  f_val <- summary_out[[1]]$`F value`[1]
  p_val <- summary_out[[1]]$`Pr(>F)`[1]
  df1 <- summary_out[[1]]$Df[1]   # Between groups df
  df2 <- summary_out[[1]]$Df[2]   # Within groups df
  
  # Compute eta-squared
  eta2_out <- effectsize::eta_squared(aov_model, partial = FALSE)
  eta2_val <- eta2_out$Eta2[1]   # take the first row's Eta2
  
  data.frame(
    measure = var,
    F_value = round(f_val, 2),
    df = paste0(df1, ", ", df2),
    p_value = round(p_val, 4),
    eta2 = round(eta2_val, 3)
  )
})

# Combine into a data frame
anova_results_df <- do.call(rbind, anova_results)

# Save to text file
sink(file.path(descriptive_stats_dir, "anova_groupwise_tests.txt"))
cat("===== One-way ANOVA Results by Group =====\n\n")
print(anova_results_df, row.names = FALSE)
sink()

# -------------------------------------------------------------------------
# 4. Correlation Among Flexibility Measures
# Highlight which metrics are moderately or highly correlated.

# Load necessary packages
if (!requireNamespace("psych", quietly = TRUE)) install.packages("psych")
if (!requireNamespace("ggplot2", quietly = TRUE)) install.packages("ggplot2")
if (!requireNamespace("reshape2", quietly = TRUE)) install.packages("reshape2")

library(psych)
library(ggplot2)
library(reshape2)

# Output directory
cor_dir <- file.path(main_results_dir, "correlation/")
dir.create(cor_dir, recursive = TRUE, showWarnings = FALSE)

# Create dataset
flex_data <- merged_data[, c(mediators, "AuDrA")]
flex_data <- na.omit(flex_data)

# Pretty names for plot labels
pretty_labels <- c(
  "avg_entropy" = "Avg. Entropy",
  "avg_bhatt_dist" = "Avg. Bhatt. Dist.",
  "inflection_prop_entropy" = "Inflect. Prop. Entropy",
  "inflection_prop_bhatt" = "Inflect. Prop. Bhatt",
  "DSI" = "DSI",
  "AuDrA" = "AuDrA"
)

# Create a renamed copy just for plotting
colnames(flex_data) <- pretty_labels[colnames(flex_data)]

corr_results <- psych::corr.test(flex_data[, pretty_labels], adjust = "none")
cor_matrix <- corr_results$r
p_matrix <- corr_results$p

# Save correlation matrix to .txt
sink(file.path(cor_dir, "correlation_matrix_flexibility.txt"))
cat("===== Pearson Correlation Matrix Among Flexibility Measures =====\n\n")
print(round(cor_matrix, 3))

cat("\nNote. Avg. Entropy = Average Entropy; Avg. Bhatt. Dist. = Average Bhattacharyya Distance;\n")
cat("Inflect. Prop. Entropy = Inflection Proportion of Entropy; Inflect. Prop. Bhatt = Inflection Proportion of Bhattacharyya Distance;\n")
cat("DSI = Divergent Semantic Integration; AuDrA = Automated Drawing Assessment (Originality Score).\n")
sink()

# Melt the matrices
cor_df <- melt(cor_matrix)
p_df <- melt(p_matrix)

# Join into one dataframe
cor_plot_data <- left_join(cor_df, p_df, by = c("Var1", "Var2"))
names(cor_plot_data) <- c("x", "y", "cor", "p")

# Create significance labels
cor_plot_data <- cor_plot_data %>%
  mutate(
    stars = case_when(
      p < 0.001 ~ "***",
      p < 0.01  ~ "**",
      p < 0.05  ~ "*",
      TRUE      ~ ""
    ),
    label = sprintf("%.2f%s", cor, stars)
  )

# Keep upper triangle without diagonal
cor_plot_data_upper <- cor_plot_data %>%
  filter(as.numeric(factor(x)) < as.numeric(factor(y)))

ggplot(cor_plot_data_upper, aes(x = x, y = y, fill = cor)) +
  geom_tile(color = "white") +
  geom_text(aes(label = label), size = 4.5, color = "black") +
  scale_fill_gradient2(
    low = "#440154", high = "#FDE725", mid = "white",
    midpoint = 0, limit = c(-1, 1),
    name = "Pearson\nr"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1),
    panel.grid = element_blank()
  ) +
  coord_fixed() +
  labs(
    title = "Upper-Triangle Correlation Heatmap of Flexibility and Originality Measures",
    x = "", y = ""
  )

ggsave(
  filename = file.path(cor_dir, "correlation_heatmap.png"),
  plot = last_plot(),
  width = 10, height = 8, dpi = 300,
  bg = "white"  
)

# -------------------------------------------------------------------------
# 5. Mediation Results (Single-level mediation)
# A summary table (one row per mediator):
#  •	Path a (mood → mediator)
#  •	Path b (mediator → AuDrA)
#  •	Indirect effect (a × b)
#  •	95% CI
#  •	Direct effect
#  •	Total effect

# Load the helper function
source("scripts/mediation_helper_functions.R")

# -------------------------------------------------------------------------
# Perform mediation analysis (dummy coded groups)
single_level_mediation(data=agg_data, treatment_vars=c("D1", "D2"), 
                       mediator_cols=mediators, control_cols=control_cols)

# -------------------------------------------------------------------------
# 6. Multilevel Regression
# After knowing that both the direct and indirect effects of the previous 
# mediation model is not significant, we add a multilevel regression model where 
# all five mediators predict originality (AuDrA) and the repeated measures come 
# from the three drawings per participant.
if (!requireNamespace("lme4", quietly = TRUE)) install.packages("lme4")
if (!requireNamespace("sjPlot", quietly = TRUE)) install.packages("sjPlot")
library(lme4)
library(sjPlot) 

# Ensure id is a factor (for random effect)
merged_data$participant_id <- paste0(merged_data$batch_name, "_", merged_data$worker_id)
merged_data$participant_id <- as.factor(merged_data$participant_id)

# Fit multilevel regression model with random intercept per participant
mlm_model <- lmer(
  AuDrA ~ avg_entropy + avg_bhatt_dist + inflection_prop_entropy + inflection_prop_bhatt + DSI + 
    positive_affectivity + negative_affectivity + openness_to_experiences + 
    cognitive_flexibility + self_rated_artistic_skill + 
    (1 | participant_id),
  data = merged_data,
  REML = FALSE
)

# Summarize and Save Results
multilevel_regression_dir <- file.path(main_results_dir, "multilevel_regression/")
dir.create(multilevel_regression_dir , recursive = TRUE, showWarnings = FALSE)

# Save txt file
summary_path <- file.path(multilevel_regression_dir, "output.txt")
sink(summary_path)
cat("===== Multilevel Regression: Predicting Originality (AuDrA) =====\n\n")
print(summary(mlm_model))
sink()

# Save formatted table
tab_model(mlm_model, file = file.path(multilevel_regression_dir, "output.html"))

# Visualization
if (!requireNamespace("effects", quietly = TRUE)) install.packages("effects")
if (!requireNamespace("patchwork", quietly = TRUE)) install.packages("patchwork")
library(effects)
library(patchwork)

# Create predicted column
merged_data$predicted <- predict(mlm_model)

# Set base font size and line color
base_theme <- theme_minimal(base_size = 14) +
  theme(
    panel.grid = element_blank(),           # remove gridlines
    panel.background = element_blank(),     # remove panel background
    plot.background = element_blank(),      # remove overall plot background
    axis.text = element_text(color = "black"),  # darker axis text
    axis.title = element_text(color = "black"),
    plot.title = element_text(
      hjust = 0.5,                          # center title
      face = "bold",
      size = 15
    ),
    legend.position = "none"               # remove legend unless needed
  )

highlight_color <- "#2c7bb6"  # muted blue

# Panel 1: Predicted vs Observed
predicted_vs_observed_plot <- ggplot(merged_data, aes(x = predicted, y = AuDrA)) +
  geom_point(alpha = 0.6, color = "gray40", size = 2) +
  geom_abline(intercept = 0, slope = 1, color = highlight_color, linetype = "dashed", size = 1) +
  labs(title = "Predicted vs. Observed Originality Scores",
       x = "Predicted AuDrA Score", y = "Observed AuDrA Score") +
  base_theme
ggsave(file.path(multilevel_regression_dir, "predicted_vs_observed_plot.png"), 
       predicted_vs_observed_plot)

# Panel 2: Fixed Effects
fixed_effects_plot <- plot_model(
  mlm_model,
  type = "est",
  show.values = TRUE,
  value.offset = 0.3,
  title = "Fixed Effects Predicting Originality (AuDrA Score)",
  colors = highlight_color,
  dot.size = 2,
  line.size = 0.8,
  vline.color = "gray70",
  axis.labels = NULL
) + 
  base_theme

ggsave(file.path(multilevel_regression_dir, "fixed_effects_plott.png"), 
       fixed_effects_plot)

# Panel 3: Marginal Effects for Significant Predictors
significant_predictors <- c("inflection_prop_entropy", "inflection_prop_bhatt", "DSI")

effect_plot <- function(var) {
  eff <- Effect(var, mlm_model)
  df <- as.data.frame(eff)
  
  # Conditional x-axis label
  x_label <- if (grepl("inflection_prop", var)) {
    if (gsub("inflection_prop_", "", var) == "entropy") {
      "Inflection Proportion of Entropy"
    } else {
      "Inflection Proportion of Bhattacharyya Distance"
    }
  } else {
    var
  }
  
  ggplot(df, aes_string(x = var, y = "fit")) +
    geom_line(color = highlight_color, size = 1.2) +
    geom_ribbon(aes(ymin = lower, ymax = upper), fill = highlight_color, alpha = 0.2) +
    labs(title = paste("Effect of",  x_label, "on Originality (AuDrA Score)"),
         x = x_label, y = "Predicted AuDrA Score") +
    base_theme
}

effect_plots <- lapply(significant_predictors, effect_plot)

# Combine all marginal effect plots into one column
combined_effects_plot <- wrap_plots(effect_plots, ncol = 1)
ggsave(file.path(multilevel_regression_dir, "marginal_effects_plot.png"),
       plot = combined_effects_plot, width = 9, height = 10, dpi = 300)

# -------------------------------------------------------------------------
# 7. Exploratory Results (probably put in supplementary results)

# -------------------------------------------------------------------------
# 7.1. Arousal/valence as continuous IVs
# -------------------------------------------------------------------------
# Perform mediation analysis (arousal as IV)
single_level_mediation(data=agg_data, 
                       treatment_vars="arousal", 
                       mediator_cols=mediators, 
                       control_cols=control_cols)

# -------------------------------------------------------------------------
# 7.2. Moderated mediation 
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------
# Moderated mediation (arousal as IV, fit mediation for separate groups)
for (grp in unique(agg_data$group)) {
  # Filter and assign
  agg_data_filtered <- agg_data[agg_data$group == grp, ]
  
  cat("\nFitting mediation model for", grp, "group\n")
  fits <- single_level_mediation(data=agg_data_filtered, treatment_vars="arousal", 
                                 mediator_col=mediators, 
                                 control_cols=control_cols, group_label = grp)
}

# -------------------------------------------------------------------------
# Moderated mediation (arousal as IV, valence as moderator)
fits <- moderated_mediation(data=agg_data, treatment="arousal", 
                            mediator_cols=mediators, 
                            moderator="valence",
                            control_vars=control_cols)

# -------------------------------------------------------------------------
# 7.3. Focus only on the first drawing for each participant
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------
# 7.4. Remove the lower bound of DSI (copying labels for the narrative section) 
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------
# 7.5. Potential quadratic effects 
# -------------------------------------------------------------------------
# Perform mediation analysis (arousal as IV & quadratic effect)
single_level_mediation(data=agg_data, 
                       treatment_vars="arousal", 
                       mediator_cols=mediators, 
                       control_cols=control_cols,
                       quadratic = TRUE)

# -------------------------------------------------------------------------
# 7.6 Unique vs. Overlapping Variance (Variance Decomposition)
# -------------------------------------------------------------------------

# Fit regression model
model <- lm(AuDrA ~ avg_entropy + avg_bhatt_dist + inflection_prop_entropy + inflection_prop_bhatt + DSI, data = merged_data)
relimp_result <- calc.relimp(model, type = "lmg", rela = TRUE)

# Save variance decomposition
sink(file.path(cor_dir, "relative_importance_flexibility.txt"))
cat("===== Relative Importance of Flexibility Measures Predicting Originality (AuDrA) =====\n\n")
print(relimp_result)
sink()

