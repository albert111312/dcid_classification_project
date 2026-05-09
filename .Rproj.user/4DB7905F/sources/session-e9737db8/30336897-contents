# ==============================================================================
# 07_random_forest.R
# Purpose: Fit random forest model, tune parameters, evaluate on test set
# ==============================================================================

# --- 1. Load train/test data -------------------------------------------------

if (!exists("train_data")) {
  train_data <- read_csv(file.path(PROCESSED, "dcid_train.csv"), show_col_types = FALSE) %>% reload_factors()
  test_data  <- read_csv(file.path(PROCESSED, "dcid_test.csv"),  show_col_types = FALSE) %>% reload_factors()
  cat("Loaded train/test from CSV.\n")
}

# --- 2. Tune mtry using OOB error --------------------------------------------

cat("\n--- Tuning mtry ---\n")
n_predictors <- length(PREDICTORS)

# Single seed before the loop — each iteration advances the RNG state, so the
# 8 forests use independent bootstrap draws (not 8 copies of the same draw).
set.seed(42)
tuning_results <- map_dfr(seq_len(n_predictors), function(m) {
  rf_temp <- randomForest(
    MODEL_FORMULA,
    data  = train_data,
    ntree = 500,
    mtry  = m
  )
  oob <- rf_temp$err.rate[500, "OOB"]
  cat(sprintf("  mtry = %d: OOB error = %.4f\n", m, oob))
  data.frame(mtry = m, oob_error = oob)
})

best_mtry <- tuning_results$mtry[which.min(tuning_results$oob_error)]
cat(sprintf("\nBest mtry: %d (OOB error: %.4f)\n", best_mtry,
            min(tuning_results$oob_error)))

# --- 4. Refit with best mtry -------------------------------------------------

set.seed(42)
rf_model <- randomForest(
  MODEL_FORMULA,
  data       = train_data,
  ntree      = 500,
  mtry       = best_mtry,
  importance = TRUE
)

cat("\n===== TUNED RANDOM FOREST =====\n")
print(rf_model)

# --- 5. Variable importance ---------------------------------------------------

cat("\n--- Variable Importance ---\n")
importance_df <- as.data.frame(importance(rf_model))
importance_df$Variable <- rownames(importance_df)
importance_df <- importance_df %>% arrange(desc(MeanDecreaseGini))
print(importance_df)

png(file.path(FIG_DIAGNOSTICS, "rf_importance.png"), width = 700, height = 500)
varImpPlot(rf_model, main = "Random Forest — Variable Importance")
dev.off()

# --- 6. Predict on test set ---------------------------------------------------

test_pred_rf  <- predict(rf_model, newdata = test_data, type = "class")
test_probs_rf <- predict(rf_model, newdata = test_data, type = "prob")[, "Strategic"]

# --- 7. Confusion matrix and metrics -----------------------------------------

cm_rf <- confusionMatrix(test_pred_rf, test_data$cyber_type,
                          positive = "Strategic")
plot_confusion_matrix(cm_rf, "Random Forest",
                      file.path(TABLES, "cm_rf.png"))

cat("\n===== CONFUSION MATRIX (RANDOM FOREST) =====\n")
print(cm_rf)

# --- 8. ROC and AUC ----------------------------------------------------------

roc_rf <- roc(test_data$cyber_type, test_probs_rf,
              levels = c("Tactical", "Strategic"),
              direction = "<")

rf_results <- build_results("Random Forest", rf_model,
                            test_pred_rf, test_probs_rf,
                            cm_rf, roc_rf,
                            best_mtry = best_mtry)

cat(sprintf("\nAUC: %.4f\n", rf_results$auc))

png(file.path(FIG_DIAGNOSTICS, "roc_rf.png"), width = 600, height = 500)
plot(roc_rf, main = "ROC Curve — Random Forest",
     col = "#E67E22", lwd = 2, print.auc = TRUE)
dev.off()

# --- 9. OOB error plot --------------------------------------------------------

png(file.path(FIG_DIAGNOSTICS, "rf_oob_error.png"), width = 700, height = 500)
plot(rf_model, main = "Random Forest — OOB Error Rate by Number of Trees")
legend("topright", colnames(rf_model$err.rate), col = 1:3, lty = 1:3)
dev.off()

# --- 10. Save -----------------------------------------------------------------

saveRDS(rf_model,   file.path(MODELS, "rf_model.rds"))
saveRDS(rf_results, file.path(MODELS, "rf_results.rds"))

cat("\nSaved: rf_model.rds, rf_results.rds\n")
cat("Random Forest complete.\n")
