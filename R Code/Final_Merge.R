# Load necessary libraries
library(tidyverse)
library(here)

# -------------------------------
# Step 1: Load your four datasets
# -------------------------------

# Load data using portable paths
legislators <- read_csv(here("Data", "modified_data", "legislators_race_gender.csv"))
# For full sample analysis, use: full_candidate_demographic_percentages.csv
# For non-incumbent analysis, use: nonincumbent_candidate_demographic_percentages.csv
candidates <- read_csv(here("Data", "modified_data", "nonincumbent_candidate_demographic_percentages.csv"))

competitiveness <- read_csv(here("Data", "original_data", "district_competiveness.csv"))
demographics <- read_csv(here("Data", "original_data", "district_demographics.csv"))


# -------------------------------
# Step 2: Prepare Legislators Data
# -------------------------------
legislators_clean <- legislators %>%
  mutate(
    nonwhite_legislator_2022 = if_else(race_binary == "Non-White", 1, 0),
    woman_legislator_2022 = if_else(predicted_gender == "female", 1, 0)
  ) %>%
  select(state, statehouse_district_number, nonwhite_legislator_2022, woman_legislator_2022)

# -------------------------------
# Step 3: Prepare Candidate Data
# -------------------------------
candidates_clean <- candidates %>%
  mutate(
    nonwhite_candidates_2024 = pct_nonwhite,
    women_candidates_2024 = pct_female
  ) %>%
  select(state, statehouse_district_number, nonwhite_candidates_2024, women_candidates_2024)

# -------------------------------
# Step 4: Prepare Competitiveness Data
# -------------------------------
competitiveness_clean <- competitiveness %>%
  mutate(
    margin_of_victory = pct_margin_of_victory
  ) %>%
  select(state, statehouse_district_number, margin_of_victory)

# -------------------------------
# Step 5: Prepare Demographics Data
# -------------------------------
demographics_clean <- demographics %>%
  mutate(
    percent_nonwhite_voters = pct_nonwhite,
    percent_women_voters = pct_female
  ) %>%
  select(state, statehouse_district_number, percent_nonwhite_voters, percent_women_voters)

# -------------------------------
# Step 6: Merge Everything Together
# -------------------------------
merged_data <- legislators_clean %>%
  left_join(candidates_clean, by = c("state", "statehouse_district_number")) %>%
  left_join(competitiveness_clean, by = c("state", "statehouse_district_number")) %>%
  left_join(demographics_clean, by = c("state", "statehouse_district_number"))

# -------------------------------
# Step 7: Export
# -------------------------------
# For full sample: write_csv(merged_data, here("Data", "modified_data", "full_merged_regression_dataset.csv"))
write_csv(merged_data, here("Data", "modified_data", "nonincumbent_merged_regression_dataset.csv"))

