# ==============================================================================
# 06_decision_tree.R
# Purpose: Fit decision tree model, prune, evaluate on test set
# ==============================================================================

# --- 1. Load train/test data -------------------------------------------------

if (!exists("train_data")) {
  train_data <- read_csv(file.path(PROCESSED, "dcid_train.csv"), show_col_types = FALSE) %>% reload_factors()
  test_data  <- read_csv(file.path(PROCESSED, "dcid_test.csv"),  show_col_types = FALSE) %>% reload_factors()
  cat("Loaded train/test from CSV.\n")
}

# --- 2. Fit full decision tree ------------------------------------------------

dtree_full <- rpart(MODEL_FORMULA,
                    data    = train_data,
                    method  = "class",
                    control = rpart.control(cp = 0.001, minsplit = 10))

cat("\n===== FULL TREE =====\n")
print(dtree_full)
printcp(dtree_full)

# --- 3. Prune tree using 1-SE rule -------------------------------------------

# 1-SE rule: smallest tree within 1 SE of the minimum cross-validated error
cp_table   <- dtree_full$cptable
min_idx    <- which.min(cp_table[, "xerror"])
min_xerror <- cp_table[min_idx, "xerror"]
min_xstd   <- cp_table[min_idx, "xstd"]
cp_1se     <- max(cp_table[cp_table[, "xerror"] <= min_xerror + min_xstd, "CP"])

cat(sprintf("\n1-SE rule cp: %.5f\n", cp_1se))

dtree_pruned <- prune(dtree_full, cp = cp_1se)

cat("\n===== PRUNED TREE =====\n")
print(dtree_pruned)

# --- 4. Visualize tree --------------------------------------------------------

png(file.path(FIG_DIAGNOSTICS, "decision_tree.png"), width = 900, height = 600)
rpart.plot(dtree_pruned,
           type = 4,
           extra = 104,
           fallen.leaves = TRUE,
           main = "Decision Tree — Strategic vs. Tactical Cyber Activity",
           box.palette = c("#D3C3F2", "#F0DAA2"))
dev.off()

# Variable importance
cat("\n--- Variable Importance ---\n")
vi_dtree <- dtree_pruned$variable.importance
print(sort(vi_dtree, decreasing = TRUE))

# --- 5. Predict on test set ---------------------------------------------------

test_probs_dtree <- predict(dtree_pruned, newdata = test_data, type = "prob")[, "Strategic"]
test_pred_dtree  <- predict(dtree_pruned, newdata = test_data, type = "class")

# --- 6. Confusion matrix and metrics -----------------------------------------

cm_dtree <- confusionMatrix(test_pred_dtree, test_data$cyber_type,
                             positive = "Strategic")

plot_confusion_matrix(cm_dtree, "Decision Tree",
                      file.path(TABLES, "cm_dtree.png"))

cat("\n===== CONFUSION MATRIX =====\n")
print(cm_dtree)

# --- 7. Variable Importance -------------------------------------------------
png("FIG_DIAGNOSTICS, dtree_importance.png", width = 700, height = 500)
vi_df <- data.frame(
  Variable = names(dtree_pruned$variable.importance),
  Importance = dtree_pruned$variable.importance
) %>%
  arrange(Importance)

par(mar = c(5, 12, 4, 2))
dotchart(vi_df$Importance,
         labels = vi_df$Variable,
         pch = 1,
         main = "Decision Tree — Variable Importance",
         xlab = "Importance")
dev.off()

# --- 8. ROC and AUC ----------------------------------------------------------

roc_dtree <- roc(test_data$cyber_type, test_probs_dtree,
                 levels = c("Tactical", "Strategic"),
                 direction = "<")

dtree_results <- build_results("Decision Tree", dtree_pruned,
                               test_pred_dtree, test_probs_dtree,
                               cm_dtree, roc_dtree)

cat(sprintf("\nAUC: %.4f\n", dtree_results$auc))

png(file.path(FIG_DIAGNOSTICS, "roc_dtree.png"), width = 600, height = 500)
plot(roc_dtree, main = "ROC Curve — Decision Tree",
     col = "#27AE60", lwd = 2, print.auc = TRUE)
dev.off()

# --- 9. Save ------------------------------------------------------------------

saveRDS(dtree_pruned,  file.path(MODELS, "dtree_model.rds"))
saveRDS(dtree_results, file.path(MODELS, "dtree_results.rds"))

cat("\nSaved: dtree_model.rds, dtree_results.rds\n")
cat("Decision Tree complete.\n")
