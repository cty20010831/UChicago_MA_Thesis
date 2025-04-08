################################################################################
# This function runs the single-level mediation analysis using lavaan.
################################################################################
single_level_mediation <- function(
    data,
    treatment_vars,
    mediator_cols,
    outcome_col = "AuDrA",
    control_cols = NULL,
    group_label = NULL, 
    n_boot = 5000,
    quadratic = FALSE,
    results_dir = "results/main_results/mediation/"
) {
  if (!requireNamespace("lavaan", quietly = TRUE)) install.packages("lavaan")
  library(lavaan)
  library(semPlot)
  
  # Define effect label
  effect_label_base <- paste(treatment_vars, collapse = "_")
  effect_label <- if (quadratic) paste0(effect_label_base, "_quadratic") else effect_label_base
  
  df_name <- deparse(substitute(data))
  output_id <- ifelse(is.null(group_label), df_name, paste0(df_name, "_", group_label))
  
  # Create directories
  summary_txt_dir <- file.path(results_dir, "single-level/")
  dir.create(summary_txt_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Shared summary path
  summary_txt_path <- paste0(summary_txt_dir, output_id, "_", effect_label, "_summary.txt")
  sink(summary_txt_path)
  cat("===== Summary of lavaan mediation models (multiple mediators) =====\n")
  if (quadratic) cat("Model includes quadratic term(s): ", paste0(treatment_vars, "_sq"), "\n")
  sink(NULL)
  
  if (quadratic) {
    for (var in treatment_vars) {
      quad_var <- paste0(var, "_sq")
      if (!quad_var %in% names(data)) {
        data[[quad_var]] <- data[[var]]^2
      }
    }
  }
  
  for (mediator_col in mediator_cols) {
    cat("Running model with mediator:", mediator_col, "\n")
    
    # Setup variables
    if (quadratic) {
      treatment_vars_expanded <- unlist(lapply(treatment_vars, function(var) c(var, paste0(var, "_sq"))))
    } else {
      treatment_vars_expanded <- treatment_vars
    }
    
    # Check required columns
    needed_cols <- c(treatment_vars_expanded, mediator_col, outcome_col)
    if (!is.null(control_cols)) {
      needed_cols <- c(needed_cols, control_cols)
    }
    
    missing_cols <- setdiff(needed_cols, names(data))
    if (length(missing_cols) > 0) {
      warning("Skipping mediator ", mediator_col, ": missing columns: ", paste(missing_cols, collapse = ", "))
      next
    }
    
    # Path labels
    a_labels <- paste0("a", seq_along(treatment_vars_expanded))
    c_labels <- paste0("c", seq_along(treatment_vars_expanded))
    
    # Mediator model
    mediator_terms <- paste(paste0(a_labels, "*", treatment_vars_expanded), collapse = " + ")
    if (!is.null(control_cols) && length(control_cols) > 0) {
      mediator_terms <- paste(mediator_terms, paste(control_cols, collapse = " + "), sep = " + ")
    }
    mediator_formula <- paste0(mediator_col, " ~ ", mediator_terms)
    
    # Outcome model
    outcome_terms <- paste(paste0(c_labels, "*", treatment_vars_expanded), collapse = " + ")
    outcome_formula <- paste0(outcome_col, " ~ ", outcome_terms, " + b*", mediator_col)
    if (!is.null(control_cols) && length(control_cols) > 0) {
      outcome_formula <- paste(outcome_formula, paste(control_cols, collapse = " + "), sep = " + ")
    }
    
    # Define effects
    define_effects <- ""
    for (i in seq_along(treatment_vars_expanded)) {
      var <- treatment_vars_expanded[i]
      define_effects <- paste0(
        define_effects,
        "\nindirect_", var, " := ", a_labels[i], " * b",
        "\ndirect_", var, " := ", c_labels[i],
        "\ntotal_", var, " := indirect_", var, " + direct_", var, "\n"
      )
    }
    
    # Combine full model
    lavaan_model <- paste(mediator_formula, outcome_formula, define_effects, sep = "\n")
    
    # Fit model with bootstrapping
    fit <- sem(
      model = lavaan_model,
      data = data,
      se = "bootstrap",
      bootstrap = n_boot,
      meanstructure = TRUE
    )
    
    # Append summary to txt
    sink(summary_txt_path, append = TRUE)
    cat("\n\n---------------------------\n")
    cat("Mediator:", mediator_col, "\n")
    cat("---------------------------\n\n")
    print(summary(fit, standardized = TRUE, fit.measures = TRUE, ci = TRUE, rsquare = TRUE, nd = 3))
    sink()
  }
}

################################################################################
# This function performs mediation analysis using processR. 
################################################################################
moderated_mediation <- function(
    data,
    treatment,
    mediator_cols,
    moderator,
    outcome = "AuDrA",
    control_vars = NULL,
    results_dir = "results/main_results/mediation/"
) {
  if (!requireNamespace("processR", quietly = TRUE)) {
    install.packages("remotes")
    remotes::install_github("cardiomoon/processR")
  }
  if (!requireNamespace("lavaan", quietly = TRUE)) install.packages("lavaan")
  
  library(processR)
  library(lavaan)
  
  effect_label <- paste0(treatment, "_moderator_", moderator)
  
  # Ensure moderator is numeric
  data[[moderator]] <- as.numeric(data[[moderator]])
  
  # Create shared summary file
  summary_txt_dir <- file.path(results_dir, "moderated_mediation/")
  dir.create(summary_txt_dir, recursive = TRUE, showWarnings = FALSE)
  summary_txt_path <- paste0(summary_txt_dir, effect_label, "_summary.txt")
  
  sink(summary_txt_path)
  cat("===== Moderated Mediation Summary (PROCESS Model 7) =====\n\n")
  sink(NULL)
  
  results_list <- list()
  
  for (mediator in mediator_cols) {
    cat("\nRunning model with mediator:", mediator, "\n")
    
    # Check columns
    needed <- c(treatment, moderator, mediator, outcome, control_vars)
    missing <- setdiff(needed, names(data))
    if (length(missing) > 0) {
      warning("Skipping ", mediator, ": missing columns - ", paste(missing, collapse = ", "))
      next
    }
    
    # Build model using `tripleEquation` (PROCESS-style)
    moderator_spec <- list(name = moderator, site = list(c("a", "c")))
    model_eq <- processR::tripleEquation(X = treatment, M = mediator, Y = outcome, moderator = moderator_spec)
    
    # Fit model with lavaan
    fit <- lavaan::sem(model = model_eq, data = data, se = "bootstrap", bootstrap = 5000)
    
    # Append to summary
    sink(summary_txt_path, append = TRUE)
    cat("\n\n---------------------------\nMediator:", mediator, "\n---------------------------\n\n")
    print(summary(fit, standardized = TRUE, fit.measures = TRUE, ci = TRUE))
    sink()
  }
}

################################################################################
# This function runs the multi-level mediation analysis using lavaan.
################################################################################
multilevel_mediation <- function(
    data,
    id_col,
    treatment_vars,
    mediator_cols,
    outcome_col = "AuDrA",
    control_cols = NULL,
    group_label = NULL,
    n_boot = 5000,
    results_dir = "results/main_results/mediation/"
) {
  if (!requireNamespace("lme4", quietly = TRUE)) install.packages("lme4")
  if (!requireNamespace("mediation", quietly = TRUE)) install.packages("mediation")
  
  library(lme4)
  library(mediation)
  
  effect_label <- paste(treatment_vars, collapse = "_")
  df_name <- deparse(substitute(data))
  output_id <- ifelse(is.null(group_label), df_name, paste0(df_name, "_", group_label))
  
  # File paths
  summary_dir <- file.path(results_dir, "multi-level/")
  dir.create(summary_dir, recursive = TRUE, showWarnings = FALSE)
  summary_txt_path <- file.path(summary_dir, paste0(output_id, "_", effect_label, "_summary.txt"))
  
  # Start summary file
  sink(summary_txt_path)
  cat("===== Multilevel mediation models (lme4 + mediation) =====\n\n")
  sink(NULL)
  
  for (mediator_col in mediator_cols) {
    cat("Running multilevel mediation with mediator:", mediator_col, "\n")
    
    # -----------------------
    # Check required variables
    needed <- c(id_col, treatment_vars, mediator_col, outcome_col, control_cols)
    missing <- setdiff(needed, names(data))
    if (length(missing) > 0) {
      warning("Skipping ", mediator_col, ": missing columns - ", paste(missing, collapse = ", "))
      next
    }
    
    # -----------------------
    # Build formulas
    treat_str <- paste(treatment_vars, collapse = " + ")
    controls_str <- if (!is.null(control_cols)) paste(control_cols, collapse = " + ") else ""
    
    mediator_formula <- as.formula(
      paste(mediator_col, "~", treat_str,
            if (controls_str != "") paste("+", controls_str),
            "+ (1 |", id_col, ")")
    )
    
    outcome_formula <- as.formula(
      paste(outcome_col, "~", treat_str, "+", mediator_col,
            if (controls_str != "") paste("+", controls_str),
            "+ (1 |", id_col, ")")
    )
    
    # -----------------------
    # Fit models
    cat("Fitting mediator model...\n")
    fitM <- lmer(mediator_formula, data = data, REML = FALSE)
    
    cat("Fitting outcome model...\n")
    fitY <- lmer(outcome_formula, data = data, REML = FALSE)
    
    # -----------------------
    # Run mediation analysis
    cat("Running mediation...\n")
    med_out <- mediate(
      model.m = fitM,
      model.y = fitY,
      treat = treatment_vars[1],  # mediation only allows 1 treatment
      mediator = mediator_col,
      sims = n_boot,
      boot = FALSE
    )
    
    # -----------------------
    # Save summary
    sink(summary_txt_path, append = TRUE)
    cat("\n\n---------------------------\n")
    cat("Mediator:", mediator_col, "\n")
    cat("---------------------------\n\n")
    print(summary(med_out))
    sink()
  }
}