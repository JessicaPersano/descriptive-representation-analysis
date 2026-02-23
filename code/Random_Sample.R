# Load packages
library(dplyr)
library(readr)
library(here)

# Load cleaned legislator and candidate datasets using portable paths
legislators <- read_csv(here("data", "modified_data", "legislators_race_gender.csv"))
candidates <- read_csv(here("data", "modified_data", "candidates_race_gender.csv"))

# Set seed for reproducibility
set.seed(2025)

# Reviewer names
reviewers <- c("Jessica", "Eddie", "Jolie")

# Sample 75 candidates and assign reviewers
candidates_sample <- candidate_race_gender %>%
  sample_n(75) %>%  # Randomly select 75 candidates
  mutate(assigned_to = sample(rep(reviewers, length.out = 75))) %>%  # Randomly assign to 3 reviewers
  select(
    state,
    statehouse_district_number,
    full_name,
    predicted_gender,
    predicted_race,
    race_binary,
    assigned_to
  )

# Sample 30 legislators and assign reviewers
legislators_sample <- legislator_race_gender %>%
  sample_n(30) %>%
  mutate(assigned_to = sample(rep(reviewers, length.out = 30))) %>%
  select(
    state,
    statehouse_district_number,
    full_name,
    predicted_gender,
    predicted_race,
    race_binary,
    assigned_to
  )

# Export to CSVs
write_csv(candidates_sample, here("data", "modified_data", "candidates_random_validation.csv"))
write_csv(legislators_sample, here("data", "modified_data", "legislators_random_validation.csv"))