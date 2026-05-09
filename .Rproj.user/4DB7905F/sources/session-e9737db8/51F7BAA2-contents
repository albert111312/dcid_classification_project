# =============================================================================
# 01_data_import_cleaning.R
# Purpose: Import raw DCID 2.0 data, clean, create dependent variable,
#          and save processed dataset
# =============================================================================

# RAW_XLSX, CLEANED_RDS, CLEANED_CSV are defined in 01_config.R.
SCRIPT_PATH <- file.path(CODE, "01_data_import_cleaning.R")

# --- 0. Cache check ----------------------------------------------------------
# Skip the import + clean step if the cached RDS is newer than both the raw
# xlsx and this script. The cleaning rules are deterministic, so re-running
# is just I/O cost. Delete the RDS (or touch the xlsx) to force a re-run.

cache_fresh <- file.exists(CLEANED_RDS) &&
               file.mtime(CLEANED_RDS) > file.mtime(RAW_XLSX) &&
               file.mtime(CLEANED_RDS) > file.mtime(SCRIPT_PATH)

if (cache_fresh) {
  dcid <- readRDS(CLEANED_RDS)
  cat("Using cached dcid_cleaned.rds (raw + script unchanged since last run).\n")
  cat("Rows:", nrow(dcid), "\n")
  cat("=== Script 01 skipped (cached) ===\n")
} else {

  # --- 1. Import raw data ----------------------------------------------------

  dcid_raw <- read_excel(RAW_XLSX)

  cat("Raw data dimensions:", nrow(dcid_raw), "rows x", ncol(dcid_raw), "columns\n")
  cat("Column names:\n")
  print(names(dcid_raw))

  # --- 2. Inspect structure --------------------------------------------------

  str(dcid_raw)
  summary(dcid_raw)

  # Check for missing values in key analysis variables
  key_variables <- c("severity", "cyber_objective", "targettype",
                     "information_operation", "Ransomware", "Supply Ch",
                     "method", "damage type", "Crit Inf")

  cat("\n--- Missing values in key variables ---\n")
  present <- intersect(key_variables, names(dcid_raw))
  print(colSums(is.na(dcid_raw[, present])))
  absent <- setdiff(key_variables, names(dcid_raw))
  if (length(absent) > 0) {
    cat("Note: not present in raw data:", paste(absent, collapse = ", "), "\n")
  }

  # --- 3. Clean and rename variables -----------------------------------------

  dcid <- dcid_raw %>%
    rename(
      incident_num      = Cyberincidentnum,
      dyad_pair         = Dyadpair,
      state_a           = StateA,
      state_b           = StateB,
      incident_name     = Name,
      start_date        = interactionstartdate,
      end_date          = interactionenddate,
      method            = method,
      target_type       = targettype,
      initiator         = initiator,
      cyber_objective   = cyber_objective,
      cio               = information_operation,
      obj_achievement   = objective_achievement,
      concession        = `Concession`,
      third_party       = `3rdpartyinitiator`,
      severity          = severity,
      damage_type       = `damage type`,
      crit_infra        = `Crit Inf`,
      supply_chain      = `Supply Ch`,
      ransomware        = Ransomware
    ) %>%
    # Keep only variables needed for analysis + identifiers
    select(
      incident_num, incident_name, state_a, state_b, initiator,
      method, target_type, cyber_objective, cio, obj_achievement,
      concession, third_party, severity, damage_type, crit_infra,
      supply_chain, ransomware
    )

  cat("\nCleaned data dimensions:", nrow(dcid), "rows x", ncol(dcid), "columns\n")

  # --- 4. Recode variables as proper types -----------------------------------

  dcid <- dcid %>%
    mutate(
      # Method: collapse decimal subcategories into main categories
      # 1 = Vandalism, 2 = DDoS, 3 = Network Intrusion, 4 = Network Infiltration
      # Anything outside [1, 5) becomes NA — checked below so it fails loudly.
      method_cat = case_when(
        method >= 1 & method < 2 ~ 1L,
        method >= 2 & method < 3 ~ 2L,
        method >= 3 & method < 4 ~ 3L,
        method >= 4 & method < 5 ~ 4L,
        TRUE                     ~ NA_integer_
      ),
      method_cat = factor(method_cat,
                          levels = 1:4,
                          labels = c("Vandalism", "DDoS",
                                     "Network_Intrusion", "Network_Infiltration")),

      # Target type
      target_type = factor(target_type,
                           levels = 1:3,
                           labels = c("Private", "Govt_NonMil", "Govt_Military")),

      # Coercive objective
      cyber_objective = factor(cyber_objective,
                               levels = 1:4,
                               labels = c("Disruption", "ST_Espionage",
                                          "LT_Espionage", "Degradation")),

      # Binary variables as factors. factor_strict stops loudly if any value
      # is outside 0/1 — same defense as method_cat above.
      cio             = factor_strict(cio,             0:1, c("Absent", "Present"), "cio"),
      obj_achievement = factor_strict(obj_achievement, 0:1, c("No", "Yes"),         "obj_achievement"),
      concession      = factor_strict(concession,      0:1, c("No", "Yes"),         "concession"),
      third_party     = factor_strict(third_party,     0:1, c("No", "Yes"),         "third_party"),
      supply_chain    = factor_strict(supply_chain,    0:1, c("No", "Yes"),         "supply_chain"),
      ransomware      = factor_strict(ransomware,      0:1, c("No", "Yes"),         "ransomware"),

      # Damage type
      damage_type = factor(damage_type,
                           levels = 1:4,
                           labels = c("Direct_Immediate", "Direct_Delayed",
                                      "Indirect_Immediate", "Indirect_Delayed")),

      # Critical infrastructure - group into broader categories for modeling
      crit_infra_cat = case_when(
        crit_infra == 6              ~ "Defense",
        crit_infra == 8              ~ "Energy",
        crit_infra == 9              ~ "Financial",
        crit_infra == 11             ~ "Govt_Facilities",
        crit_infra == 13             ~ "Info_Technology",
        crit_infra == 14             ~ "Nuclear",
        crit_infra == 2              ~ "Commercial_Facilities",
        crit_infra == 3              ~ "Communications",
        crit_infra == 12             ~ "Healthcare",
        crit_infra == 15             ~ "Transportation",
        crit_infra == 17             ~ "Other_NonTraditional",
        TRUE                         ~ "Other"
      ),
      crit_infra_cat = factor(crit_infra_cat),

      # Severity as ordered factor (data dictionary: ordinal 0–10)
      severity = factor(severity, levels = 0:10, ordered = TRUE)
    )

  # Fail loudly if any non-NA method value fell outside the mapped buckets.
  unmapped_method <- dcid %>%
    filter(is.na(method_cat) & !is.na(method)) %>%
    pull(method) %>%
    unique()
  if (length(unmapped_method) > 0) {
    stop("Unmapped method values: ", paste(unmapped_method, collapse = ", "),
         ". Update the method_cat case_when() in 01_data_import_cleaning.R.")
  }

  # --- 5. Create dependent variable ------------------------------------------
  #
  # OPERATIONALIZATION RULE (locked in):
  # An incident is STRATEGIC (1) if it meets 2 or more of these 4 indicators:
  #   1. Severity >= 4
  #   2. Coercive objective = Long-term espionage (3) or Degradation (4)
  #   3. Government target (target type 2 or 3)
  #   4. CIO present
  # Otherwise: TACTICAL (0)
  #
  # Literature support:
  #   - Severity: Valeriano, Jensen, & Maness (2018)
  #   - Coercive objective: Valeriano, Jensen, & Maness (2018)
  #   - Target type: Peter & Ohakpougwu (2024)
  #   - CIO: Nakasone (2019); DCID codebook
  # Requiring 2+ ensures no single variable drives the classification.

  dcid <- dcid %>%
    mutate(
      # Individual indicator flags
      ind_severity   = as.integer(as.numeric(as.character(severity)) >= 4),
      ind_objective  = as.integer(cyber_objective %in% c("LT_Espionage", "Degradation")),
      ind_gov_target = as.integer(target_type %in% c("Govt_NonMil", "Govt_Military")),
      ind_cio        = as.integer(cio == "Present"),

      # Count how many indicators are met
      indicator_count = ind_severity + ind_objective + ind_gov_target + ind_cio,

      # Dependent variable
      cyber_type = factor(
        ifelse(indicator_count >= 2, "Strategic", "Tactical"),
        levels = c("Tactical", "Strategic")
      )
    )

  # Fail if any row ended up with NA cyber_type. NAs cascade from
  # missing severity / cyber_objective / target_type / cio, so this catches
  # data-quality issues before they shrink the modeling sample.
  n_missing_dv <- sum(is.na(dcid$cyber_type))
  if (n_missing_dv > 0) {
    stop(n_missing_dv, " row(s) have NA cyber_type — likely from missing ",
         "severity, cyber_objective, target_type, or cio. Investigate.")
  }

  # --- 6. Verify the dependent variable --------------------------------------

  cat("\n===== DEPENDENT VARIABLE VERIFICATION =====\n")
  cat("\n--- Distribution ---\n")
  print(table(dcid$cyber_type))
  cat(sprintf("\nStrategic: %d (%.1f%%)\n",
              sum(dcid$cyber_type == "Strategic"),
              mean(dcid$cyber_type == "Strategic") * 100))
  cat(sprintf("Tactical:  %d (%.1f%%)\n",
              sum(dcid$cyber_type == "Tactical"),
              mean(dcid$cyber_type == "Tactical") * 100))

  # Cross-tabs
  cat("\nDV by each indicator:\n")
  cat("\nSeverity >= 4:\n")
  print(table(dcid$cyber_type, dcid$ind_severity,
              dnn = c("cyber_type", "sev_ge4")))

  cat("\nObjective = LT Espionage or Degradation:\n")
  print(table(dcid$cyber_type, dcid$ind_objective,
              dnn = c("cyber_type", "strat_obj")))

  cat("\nGovernment target:\n")
  print(table(dcid$cyber_type, dcid$ind_gov_target,
              dnn = c("cyber_type", "gov_tgt")))

  cat("\nCIO present:\n")
  print(table(dcid$cyber_type, dcid$ind_cio,
              dnn = c("cyber_type", "cio")))

  cat("\nIndicator count distribution:\n")
  print(table(dcid$indicator_count))

  # --- 7. Spot-check known cases ---------------------------------------------

  cat("\n--- Spot-checks ---\n")

  spot_check <- function(name_pattern, expected) {
    row <- dcid %>% filter(grepl(name_pattern, incident_name, fixed = TRUE))
    if (nrow(row) > 0) {
      result <- as.character(row$cyber_type[1])
      match_flag <- ifelse(result == expected, "OK", "** MISMATCH **")
      cat(sprintf("  %-42s => %-10s (expect: %-10s) %s  [indicators=%d]\n",
                  substr(row$incident_name[1], 1, 42),
                  result, expected, match_flag,
                  row$indicator_count[1]))
    }
  }

  spot_check("Stuxnet_A",                             "Strategic")
  spot_check("SUNBURST",                              "Strategic")
  spot_check("Sony Hack",                             "Strategic")
  spot_check("NotPetya_A",                            "Strategic")
  spot_check("WannaCry- US Critical Infrastructure",  "Strategic")
  spot_check("Operation Ababil",                      "Tactical")
  spot_check("GitHub Hack",                           "Tactical")
  spot_check("Yahoo breach 1",                        "Tactical")

  # --- 8. Predictor selection note -------------------------------------------
  #
  # DATA LEAKAGE NOTE:
  # The DV is constructed from severity, cyber_objective, target_type, and cio,
  # so those four variables are excluded as predictors — otherwise the models
  # would just relearn the coding rule. The 8 predictors actually fed to the
  # classifiers are selected in 03_feature_engineering.R after sparse-category
  # collapsing; see PREDICTORS in 01_config.R for the canonical list.

  # --- 9. Save processed datasets --------------------------------------------

  # RDS preserves factor levels — used by downstream scripts (02, 03).
  saveRDS(dcid, CLEANED_RDS)

  # CSV mirror for inspection in non-R tools (severity coerced to character
  # so the levels survive a CSV round-trip if anything ever reads it back).
  write_csv(dcid %>% mutate(severity = as.character(severity)), CLEANED_CSV)

  cat("\n=== Script 01 complete ===\n")
  cat("Saved:", CLEANED_RDS, "(pipeline format)\n")
  cat("Saved:", CLEANED_CSV, "(inspection mirror)\n")
}
