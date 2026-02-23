# Load packages
library(tidycensus)
library(dplyr)
library(tidyr)
library(stringr)
library(here)

# Load your census API key
readRenviron("~/.Renviron")  

# Variables to pull
race_vars <- c(total = "B02001_001",
               white = "B02001_002")

sex_vars <- c(male = "B01001_002",
              female = "B01001_026")

get_demographics <- function(state_abbr) {
  # Race data
  race <- get_acs(geography = "state legislative district (lower chamber)",
                  variables = race_vars,
                  state = state_abbr,
                  year = 2022,
                  survey = "acs5",
                  output = "wide") %>%
    select(GEOID, NAME, totalE, whiteE) %>%
    rename(total_pop = totalE,
           white = whiteE)
  
  # Sex data
  sex <- get_acs(geography = "state legislative district (lower chamber)",
                 variables = sex_vars,
                 state = state_abbr,
                 year = 2022,
                 survey = "acs5",
                 output = "wide") %>%
    select(GEOID, maleE, femaleE) %>%
    rename(male = maleE,
           female = femaleE)
  
  # Merge and calculate percentages
  merged <- race %>%
    left_join(sex, by = "GEOID") %>%
    mutate(
      pct_white = round((white / total_pop) * 100, 2),
      pct_nonwhite = round(100 - pct_white, 2),
      pct_male = round((male / (male + female)) * 100, 2),
      pct_female = round(100 - pct_male, 2)
    )
  
  return(merged)
}

# Run for Georgia, Nevada, and Michigan
ga_data <- get_demographics("GA")
nv_data <- get_demographics("NV")
mi_data <- get_demographics("MI")

# Combine for convenience
combined_data <- bind_rows(
  ga_data %>% mutate(state = "GA"),
  nv_data %>% mutate(state = "NV"),
  mi_data %>% mutate(state = "MI")
)

# Add statehouse district number
combined_data <- combined_data %>%
  mutate(
    statehouse_district_number = as.integer(str_extract(NAME, "\\d+"))
  )

# Export to CSV
write.csv(combined_data, here("data", "original_data", "district_demographics.csv"), row.names = FALSE)

