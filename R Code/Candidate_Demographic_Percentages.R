# ----------------------------
# Step 1: Load Required Packages
# ----------------------------
library(dplyr)
library(readr)
library(here)

# ----------------------------
# Step 2: Read Data
# ----------------------------

# Clear environment to avoid variable conflicts
rm(list = ls())

# Load final candidate datasets using portable paths
candidates <- read_csv(here("Data", "modified_data", "candidates_race_gender.csv"))

# ----------------------------
# Step 3: Filter Out Incumbents and Create Binary Gender/Race
# ----------------------------
candidates <- candidates %>%
  filter(is.na(incumbent_status) | incumbent_status != 1) %>% # removes incumbents
  mutate(
    race_binary = ifelse(predicted_race == "White", "White", "Non-White"),
    gender_binary = case_when(
      predicted_gender == "male" ~ "Male",
      predicted_gender == "female" ~ "Female",
      TRUE ~ NA_character_
    )
  )

# ----------------------------
# Step 4: Aggregate to One Row Per District
# ----------------------------
district_summary <- candidates %>%
  group_by(state, statehouse_district_number) %>%
  summarise(
    total_candidates = n(),
    
    # Proportions with explicit NA when no candidates
    pct_white = ifelse(total_candidates == 0, NA, sum(race_binary == "White", na.rm = TRUE) / total_candidates),
    pct_nonwhite = ifelse(total_candidates == 0, NA, sum(race_binary == "Non-White", na.rm = TRUE) / total_candidates),
    pct_female = ifelse(total_candidates == 0, NA, sum(gender_binary == "Female", na.rm = TRUE) / total_candidates),
    pct_male = ifelse(total_candidates == 0, NA, sum(gender_binary == "Male", na.rm = TRUE) / total_candidates),
    
    # Raw counts
    count_white = sum(race_binary == "White", na.rm = TRUE),
    count_nonwhite = sum(race_binary == "Non-White", na.rm = TRUE),
    count_female = sum(gender_binary == "Female", na.rm = TRUE),
    count_male = sum(gender_binary == "Male", na.rm = TRUE),
    
    .groups = "drop"
  )

# ----------------------------
# Step 5: Export Cleaned Summary
# ----------------------------
# For full sample: write_csv(district_summary, here("Data", "modified_data", "full_candidate_demographic_percentages.csv"))
write_csv(district_summary, here("Data", "modified_data", "nonincumbent_candidate_demographic_percentages.csv"))
