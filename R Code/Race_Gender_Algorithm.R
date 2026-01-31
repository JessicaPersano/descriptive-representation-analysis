# ----------------------------
# Step 1: Load Required Packages
# ----------------------------

# genderizeR: Interface to the genderize.io API for predicting gender from first names
# wru: For race/ethnicity estimation (not used yet but loaded for future steps)
# dplyr, readr, stringr: Tidyverse tools for data manipulation and string handling
# here: For portable file paths that work across different systems
library(genderizeR)
library(wru)
library(dplyr)
library(readr)
library(stringr)
library(here)

# ----------------------------
# Step 2: Read and Prepare Data
# ----------------------------

# Clear environment to avoid variable conflicts
rm(list = ls())

# Load cleaned legislator and candidate datasets using portable paths
legislators <- read_csv(here("Data", "modified_data", "legislators_with_county.csv"))
candidates <- read_csv(here("Data", "modified_data", "candidates_with_county.csv"))

# ----------------------------
# Step 3: Predict Gender with genderize.io API
# ----------------------------

# Load API key from environment variable (set in .Renviron file)
# To set up: copy .Renviron.example to .Renviron and add your key
my_api_key <- Sys.getenv("GENDERIZE_API_KEY")
if (my_api_key == "") stop("GENDERIZE_API_KEY not found. Please set it in your .Renviron file.")

# Helper function: splits vector of names into groups of ≤10 for API batching
split_chunks <- function(names_vec) {
  split(names_vec, ceiling(seq_along(names_vec) / 10))
}

# Helper function: queries the genderize.io API for one chunk of names
query_gender_chunk <- function(name_chunk) {
  result <- genderizeAPI(name_chunk, apikey = my_api_key)
  result$response
}

# Main function: runs prediction pipeline for a given dataset
get_gender_df <- function(df) {
  unique_names <- unique(df$first_name)
  chunks <- split_chunks(unique_names)
  bind_rows(lapply(chunks, query_gender_chunk))
}

# Run gender prediction for each dataset
leg_gender <- get_gender_df(legislators)
cand_gender <- get_gender_df(candidates)

# Rename gender columns to avoid name collisions when merging
colnames(leg_gender)[colnames(leg_gender) == "gender"] <- "predicted_gender"
colnames(leg_gender)[colnames(leg_gender) == "probability"] <- "gender_prob"
colnames(cand_gender)[colnames(cand_gender) == "gender"] <- "predicted_gender"
colnames(cand_gender)[colnames(cand_gender) == "probability"] <- "gender_prob"

# Join predicted gender/probability to each full dataset using first_name
legislators <- legislators %>%
  left_join(leg_gender, by = c("first_name" = "name"))

candidates <- candidates %>%
  left_join(cand_gender, by = c("first_name" = "name"))

# Save the updated files with gender predictions added
write_csv(legislators, here("Data", "modified_data", "legislators_with_gender.csv"))
write_csv(candidates, here("Data", "modified_data", "candidates_with_gender.csv"))

# ----------------------------
# Step 3: Optional Diagnostics for Gender Predictions
# ----------------------------

length(unique(legislators$first_name))    # Total unique first names in legislator data
length(unique(candidates$first_name))     # Total unique first names in candidate data
nrow(leg_gender)                          # API-recognized names in legislators
nrow(cand_gender)                         # API-recognized names in candidates
setdiff(unique(legislators$first_name), leg_gender$name)  # Names not returned by API
setdiff(unique(candidates$first_name), cand_gender$name)

# ----------------------------
# Step 4: Predict Race with WRU BISG
# ----------------------------

# Reload datasets with gender already included
leg_with_gender <- read_csv(here("Data", "modified_data", "legislators_with_gender.csv"))
cand_with_gender <- read_csv(here("Data", "modified_data", "candidates_with_gender.csv"))

# Format data for WRU: clean and rename key fields
prepare_for_bisg <- function(df) {
  df %>%
    mutate(party = case_when(
      party_code == 100 ~ "1",     # Democrat
      party_code == 200 ~ "2",     # Republican
      party_code == 300 ~ "0",     # Other
      TRUE ~ NA_character_
    )) %>%
    mutate(county_fips = str_pad(as.character(county_fips), 3, pad = "0")) %>%
    rename(
      surname = last_name,
      first = first_name,
      middle = middle_name,
      county = county_fips
    ) %>%
    filter(!is.na(county) & !is.na(surname)) %>%
    distinct()
}

# Prepare datasets for race prediction
leg_bisg <- prepare_for_bisg(leg_with_gender)
cand_bisg <- prepare_for_bisg(cand_with_gender)

# Run WRU BISG race predictions using name, party, and geography
predict_with_bisg <- function(df) {
  predict_race(
    voter.file = df,
    census.surname = TRUE,
    surname.only = FALSE,
    names.to.use = "surname, first, middle",
    census.geo = "county",
    census.key = Sys.getenv("CENSUS_API_KEY"),
    party = "party",
    year = "2020",
    skip_bad_geos = TRUE
  )
}

# Execute race prediction for legislators and candidates
leg_race <- predict_with_bisg(leg_bisg)
cand_race <- predict_with_bisg(cand_bisg)

aggregate_race <- function(df) {
  df %>%
    # Remove exact duplicates by candidate + geography
    distinct(first, surname, county, state, statehouse_district_number, .keep_all = TRUE) %>%
    
    # Group by individual candidate across county splits
    group_by(first, surname, state, statehouse_district_number) %>%
    
    # Average predicted probabilities across counties (if needed)
    mutate(
      avg_white = mean(pred.whi, na.rm = TRUE),
      avg_black = mean(pred.bla, na.rm = TRUE),
      avg_his   = mean(pred.his, na.rm = TRUE),
      avg_asi   = mean(pred.asi, na.rm = TRUE),
      avg_other = mean(pred.oth, na.rm = TRUE),
      
      # Assign race label based on maximum probability
      predicted_race = case_when(
        avg_white == max(avg_white, avg_black, avg_his, avg_asi, avg_other) ~ "White",
        avg_black == max(avg_white, avg_black, avg_his, avg_asi, avg_other) ~ "Black",
        avg_his   == max(avg_white, avg_black, avg_his, avg_asi, avg_other) ~ "Hispanic",
        avg_asi   == max(avg_white, avg_black, avg_his, avg_asi, avg_other) ~ "Asian",
        avg_other == max(avg_white, avg_black, avg_his, avg_asi, avg_other) ~ "Other",
        TRUE ~ NA_character_
      ),
      
      # Create a White vs. Non-White classification
      race_binary = ifelse(predicted_race == "White", "White", "Non-White")
    ) %>%
    
    # Ungroup and return as a standard dataframe
    ungroup() %>%
    as.data.frame()
}

# Run aggregation function
legislator_race_gender <- aggregate_race(leg_race)
candidate_race_gender <- aggregate_race(cand_race)

# ----------------------------
# Step 4.5: Optional Diagnostics for Race Prediction
# ----------------------------

# Check for legislators with missing predicted race
missing_leg_race <- legislator_race_gender %>%
  filter(is.na(predicted_race)) %>%
  select(first, surname, state)

cat("Number of legislators with no predicted race:", nrow(missing_leg_race), "\n")
if (nrow(missing_leg_race) > 0) {
  print(missing_leg_race)
}

# Check for candidates with missing predicted race
missing_cand_race <- candidate_race_gender %>%
  filter(is.na(predicted_race)) %>%
  select(first, surname, state)

cat("Number of candidates with no predicted race:", nrow(missing_cand_race), "\n")
if (nrow(missing_cand_race) > 0) {
  print(missing_cand_race)
}

# ----------------------------
# Step 5: Export Final Files
# ----------------------------

# Save cleaned, merged datasets with final race and gender assignments
write_csv(legislator_race_gender, here("Data", "modified_data", "legislators_race_gender.csv"))
write_csv(candidate_race_gender, here("Data", "modified_data", "candidates_race_gender.csv"))
