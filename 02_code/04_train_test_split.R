# ==============================================================================
# 04_train_test_split.R
# Purpose: Stratified 70/30 train-test split with class proportion verification
# ==============================================================================

# --- 1. Load modeling-ready data ----------------------------------------------

if (!exists("model_data")) {
  model_data <- read_csv(file.path(PROCESSED, "dcid_model_ready.csv"),
                         show_col_types = FALSE) %>%
    reload_factors()
  cat("Loaded model_data from CSV. Rows:", nrow(model_data), "\n")
}

# --- 2. Set seed and create stratified split ----------------------------------

set.seed(42)  # For reproducibility

# NOTE: incident_num is kept in train/test so individual misclassified
# incidents can be traced back later. The downstream models (glm, rpart,
# randomForest) use explicit formulas that name each predictor, so the
# id column is silently ignored during fitting and prediction.

train_index <- createDataPartition(model_data$cyber_type,
                                    p = 0.70,
                                    list = FALSE,
                                    times = 1)

train_data <- model_data[train_index, ]
test_data  <- model_data[-train_index, ]

# --- 3. Verify class proportions ---------------------------------------------

cat("\n===== SPLIT VERIFICATION =====\n")
cat(sprintf("\nFull data:   n = %d\n", nrow(model_data)))
print(prop.table(table(model_data$cyber_type)))

cat(sprintf("\nTraining:    n = %d (%.1f%%)\n",
            nrow(train_data), nrow(train_data)/nrow(model_data)*100))
print(prop.table(table(train_data$cyber_type)))

cat(sprintf("\nTest:        n = %d (%.1f%%)\n",
            nrow(test_data), nrow(test_data)/nrow(model_data)*100))
print(prop.table(table(test_data$cyber_type)))

# --- 4. Save ------------------------------------------------------------------

write_csv(train_data, file.path(PROCESSED, "dcid_train.csv"))
write_csv(test_data,  file.path(PROCESSED, "dcid_test.csv"))
cat("\nSaved: dcid_train.csv, dcid_test.csv\n")

cat("Training and testing data ready.\n")
