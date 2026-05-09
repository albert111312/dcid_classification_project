# ==============================================================================
# 08_model_comparison.R
# Purpose: Compare the three classifiers, overlaid ROC curves, final summary table
# ==============================================================================

# --- 1. Load results ----------------------------------------------------------

if (!exists("logit_results")) logit_results <- readRDS(file.path(MODELS, "logit_results.rds"))
if (!exists("dtree_results")) dtree_results <- readRDS(file.path(MODELS, "dtree_results.rds"))
if (!exists("rf_results"))    rf_results    <- readRDS(file.path(MODELS, "rf_results.rds"))

if (!exists("test_data")) {
  test_data <- read_csv(file.path(PROCESSED, "dcid_test.csv"), show_col_types = FALSE) %>%
    reload_factors()
}
# test_data$incident_num is preserved — pair with *_results$predictions
# to inspect which specific incidents each model got wrong.

# --- 2. Model comparison table ------------------------------------------------

comparison <- bind_rows(
  logit_results$metrics,
  dtree_results$metrics,
  rf_results$metrics
)

cat("\n===== MODEL COMPARISON =====\n")
print(comparison, digits = 4)
write_csv(comparison, file.path(TABLES, "model_comparison.csv"))

comparison_table <- comparison %>%
  mutate(across(where(is.numeric), ~round(.x, 3)))
table_to_png(comparison_table,
             "Model Comparison — Performance Metrics",
             file.path(TABLES, "model_comparison.png"),
             col_widths = c(2, 1, 1, 1, 1, 1))

# --- 3. Overlaid ROC curves ---------------------------------------------------

png(file.path(FIG_FINAL, "roc_comparison.png"), width = 700, height = 600)
plot(logit_results$roc, col = "#2C3E50", lwd = 2,
     main = "ROC Curve Comparison — All Three Models")
plot(dtree_results$roc, col = "#27AE60", lwd = 2, add = TRUE)
plot(rf_results$roc,    col = "#E67E22", lwd = 2, add = TRUE)
abline(a = 0, b = 1, lty = 2, col = "gray50")
legend("bottomright",
       legend = c(
         sprintf("Logistic Regression (AUC = %.3f)", logit_results$auc),
         sprintf("Decision Tree (AUC = %.3f)", dtree_results$auc),
         sprintf("Random Forest (AUC = %.3f)", rf_results$auc)
       ),
       col = c("#2C3E50", "#27AE60", "#E67E22"),
       lwd = 2)
dev.off()

# --- 4. Confusion matrices side by side ---------------------------------------

cat("\n===== CONFUSION MATRICES =====\n")

cat("\n--- Logistic Regression ---\n")
print(logit_results$confusion$table)

cat("\n--- Decision Tree ---\n")
print(dtree_results$confusion$table)

cat("\n--- Random Forest ---\n")
print(rf_results$confusion$table)

# Save confusion matrices
cm_summary <- data.frame(
  Model = c("Logistic Regression", "Decision Tree", "Random Forest"),
  TP = c(logit_results$confusion$table[2,2],
         dtree_results$confusion$table[2,2],
         rf_results$confusion$table[2,2]),
  TN = c(logit_results$confusion$table[1,1],
         dtree_results$confusion$table[1,1],
         rf_results$confusion$table[1,1]),
  FP = c(logit_results$confusion$table[2,1],
         dtree_results$confusion$table[2,1],
         rf_results$confusion$table[2,1]),
  FN = c(logit_results$confusion$table[1,2],
         dtree_results$confusion$table[1,2],
         rf_results$confusion$table[1,2])
)
cm_summary <- cm_summary %>%
  mutate(
    Accuracy  = round((TP + TN) / (TP + TN + FP + FN) * 100, 1),
    Precision = round(TP / (TP + FP) * 100, 1),
    Recall    = round(TP / (TP + FN) * 100, 1)
  )

print(cm_summary)
write_csv(cm_summary, file.path(TABLES, "cm_summary.csv"))

cm_summary_display <- cm_summary %>%
  mutate(across(c(Accuracy, Precision, Recall), ~paste0(.x, "%")))

table_to_png(cm_summary_display,
             "Model Comparison — Confusion Matrix Summary",
             file.path(TABLES, "cm_summary_table.png"),
             col_widths = c(2.5, 0.8, 0.8, 0.8, 0.8, 1.1, 1.1, 1.1))

# --- 5. McNemar's test for pairwise model comparison --------------------------

cat("\n===== PAIRWISE MODEL COMPARISONS (McNemar's Test) =====\n")

logit_correct <- logit_results$predictions == test_data$cyber_type
dtree_correct <- dtree_results$predictions == test_data$cyber_type
rf_correct    <- rf_results$predictions    == test_data$cyber_type

mc_ld <- table(logit_correct, dtree_correct)
mc_lr <- table(logit_correct, rf_correct)
mc_dr <- table(dtree_correct, rf_correct)

# Run a McNemar test, print the disagreement table + result, and return a
# one-row dataframe of summary stats for the PNG table below.
run_mcnemar <- function(tab, name_a, name_b) {
  cat(sprintf("\n--- %s vs %s ---\n", name_a, name_b))
  print(tab)
  test <- tryCatch(mcnemar.test(tab), error = function(e) {
    cat("McNemar's test not applicable:", e$message, "\n")
    NULL
  })
  if (!is.null(test)) print(test)

  data.frame(
    Comparison      = paste(name_a, "vs", name_b),
    A_Right_B_Wrong = tab[2, 1],   # A correct, B incorrect
    A_Wrong_B_Right = tab[1, 2],   # A incorrect, B correct
    Chi_Sq          = if (!is.null(test)) round(test$statistic, 3) else NA,
    P_Value         = if (!is.null(test)) format.pval(test$p.value, digits = 4) else "N/A",
    Significant     = if (!is.null(test)) ifelse(test$p.value < 0.05, "Yes", "No") else "N/A"
  )
}

mcnemar_results <- bind_rows(
  run_mcnemar(mc_ld, "Logistic Regression", "Decision Tree"),
  run_mcnemar(mc_lr, "Logistic Regression", "Random Forest"),
  run_mcnemar(mc_dr, "Decision Tree",       "Random Forest")
)

# --- 5b. McNemar results as PNG ----------------------------------------------
# Custom-rendered (rather than table_to_png) because the headers need
# two-line labels.

col_names_mc <- c("Comparison", "A_Right_B_Wrong", "A_Wrong_B_Right",
                  "Chi_Sq", "P_Value", "Significant")
col_labels   <- c("Comparison", "A Right\nB Wrong", "A Wrong\nB Right",
                  "Chi-Sq", "P-Value", "Sig (p<.05)")
col_widths_mc  <- c(3, 1.5, 1.5, 1, 1.2, 1)
col_centers_mc <- cumsum(col_widths_mc) - col_widths_mc / 2

header_mc <- data.frame(
  col   = col_centers_mc,
  label = col_labels,
  width = col_widths_mc,
  row   = 0
)

body_mc <- mcnemar_results %>%
  mutate(row_num = row_number()) %>%
  mutate(across(everything(), as.character)) %>%
  pivot_longer(cols = all_of(col_names_mc), names_to = "col_name", values_to = "value") %>%
  mutate(
    col_idx = match(col_name, col_names_mc),
    col     = col_centers_mc[col_idx],
    width   = col_widths_mc[col_idx],
    row_num = as.numeric(row_num)
  )

p_mc <- ggplot() +
  geom_tile(data = header_mc, aes(x = col, y = row, width = width),
            fill = "#2C3E50", color = "white", height = 1) +
  geom_text(data = header_mc, aes(x = col, y = row, label = label),
            color = "white", fontface = "bold", size = 3.8, lineheight = 0.9) +
  geom_tile(data = body_mc, aes(x = col, y = -row_num, width = width),
            fill = ifelse(body_mc$row_num %% 2 == 0, "#F2F6FA", "white"),
            color = "gray80", height = 1) +
  geom_text(data = body_mc, aes(x = col, y = -row_num, label = value), size = 3.8) +
  scale_y_continuous(expand = expansion(add = 0.5)) +
  labs(title = "McNemar's Test — Pairwise Model Comparisons",
       subtitle = "Tests whether two models make significantly different errors on the same test data") +
  theme_void(base_size = 13) +
  theme(
    plot.title    = element_text(face = "bold", hjust = 0.5,
                                 margin = ggplot2::margin(b = 5)),
    plot.subtitle = element_text(hjust = 0.5, color = "gray40", size = 10,
                                 margin = ggplot2::margin(b = 10)),
    plot.margin   = ggplot2::margin(20, 20, 20, 20)
  )

ggsave(file.path(TABLES, "mcnemar_results.png"),
       p_mc, width = 10, height = 3.5, dpi = 300)
cat("Saved: mcnemar_results.png\n")

# --- 6. Best model recommendation --------------------------------------------

best_idx <- which.max(comparison$AUC)
cat(sprintf("\n===== RECOMMENDATION =====\n"))
cat(sprintf("Best model by AUC: %s (AUC = %.4f)\n",
            comparison$Model[best_idx], comparison$AUC[best_idx]))

best_idx_f1 <- which.max(comparison$F1)
cat(sprintf("Best model by F1:  %s (F1 = %.4f)\n",
            comparison$Model[best_idx_f1], comparison$F1[best_idx_f1]))

cat("\nModel comparison complete.\n")
cat("All modeling and comparison scripts complete.\n")
