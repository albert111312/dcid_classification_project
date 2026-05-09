# DCID Classification Project

## Classifying State-Sponsored Cyber Activity Using the DCID 2.0 Dataset

### Research Question
Can supervised classification methods distinguish between strategic cyber operations
and tactical cyber activity using the Dyadic Cyber Incident and Campaign Dataset (DCID 2.0)?

### Dependent Variable Operationalization
An incident is classified as **strategic** (1) if it meets **two or more** of:
1. Severity >= 4
2. Coercive objective = 3 (long-term espionage) or 4 (degradation)
3. Government target (target type = 2 or 3)
4. CIO present (information_operation = 1)

Otherwise it is classified as **tactical** (0).

### Methods
- Logistic Regression
- Decision Tree
- Random Forest

### Data
- DCID 2.0 (February 2023 release), 429 observations
- 70/30 stratified train/test split

### Software
- R / RStudio
- Key packages: tidyverse, caret, rpart, randomForest, pROC

### Directory Structure
- Setup directory structure according to directory_structure.txt so intermediate and output files (csv, png, res) save in the correct sub-directories.

### Reproduction
- Use the .Rproj file and run the 00_master.R script to run the entire pipeline.
