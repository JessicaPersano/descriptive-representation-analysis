# -----------------------------
# Step 1: Load necessary packages
# -----------------------------

rm(list = ls())  # Clear the R environment to start fresh

# Define all required packages
required_packages <- c("sf", "tigris", "readxl", "dplyr", "writexl")

# Install any missing packages
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
}

# Load the necessary libraries
library(sf)         # For spatial data and shapefiles
library(tigris)     # To download census shapefiles (districts and counties)
library(readxl)     # To read Excel files
library(dplyr)      # For data wrangling
library(writexl)    # For Excel output
library(stringr)    # For string manipulation (used in name fixes)
library(readr)
library(here)       # For portable file paths

# Enable caching for tigris shapefile downloads
options(tigris_use_cache = TRUE)

# -----------------------------
# Step 2: Read Excel data
# -----------------------------

# Load the legislator and candidate data using portable paths
legislators <- read_csv(here("Data", "original_data", "legislator_data.csv"))
candidates <- read_csv(here("Data", "original_data", "candidate_data.csv"))

# Define a helper function to format district names consistently
format_district_name <- function(df) {
  df %>%
    mutate(district_name = paste0("State House District ", as.integer(statehouse_district_number)))
}

# Apply the formatting function to both datasets
legislators <- format_district_name(legislators)
candidates <- format_district_name(candidates)

# -----------------------------
# Step 3: Assign primary county per district
# -----------------------------

# This function downloads district and county shapefiles for a state,
# intersects them, and assigns each district to the county containing the largest area
get_primary_county <- function(state_abbr, state_fips) {
  message(paste("Processing", state_abbr))
  
  # Create a temporary folder for shapefiles
  temp_dir <- tempfile()
  dir.create(temp_dir)
  
  # Construct the download URL and file paths
  zip_url <- paste0("https://www2.census.gov/geo/tiger/TIGER2022/SLDL/tl_2022_", state_fips, "_sldl.zip")
  temp_zip <- file.path(temp_dir, "shapefile.zip")
  download.file(zip_url, temp_zip, mode = "wb")
  unzip(temp_zip, exdir = temp_dir)
  
  # Load the shapefile
  shp_path <- list.files(temp_dir, pattern = "\\.shp$", full.names = TRUE)
  if (length(shp_path) == 0) stop("Shapefile not found after unzip.")
  districts <- read_sf(shp_path)
  
  # Load county shapefiles and make sure both layers share the same CRS
  counties_sf <- counties(state = state_abbr, year = 2022, class = "sf")
  districts <- st_transform(districts, st_crs(counties_sf))
  
  # Fix any invalid geometries
  districts <- st_make_valid(districts)
  counties_sf <- st_make_valid(counties_sf)
  
  # Spatial intersection: find overlapping areas
  intersection <- st_intersection(districts, counties_sf)
  
  # Return a blank tibble if no intersection occurred
  if (nrow(intersection) == 0) {
    warning(paste("No intersection found for", state_abbr))
    return(tibble(
      district_name = character(),
      county_name = character(),
      county_fips = character(),
      state = character(),
      geometry = st_sfc()
    ))
  }
  
  # Calculate the area of overlap and keep the largest one per district
  intersection$area <- st_area(intersection)
  intersection %>%
    group_by(NAMELSAD) %>%
    slice_max(area, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    select(district_name = NAMELSAD, county_name = NAME, county_fips = COUNTYFP, state = STATEFP)
}

# -----------------------------
# Step 4: Run for all three states
# -----------------------------

# Run the function for Michigan, Georgia, and Nevada
mi <- get_primary_county("MI", "26")
ga <- get_primary_county("GA", "13")
nv <- get_primary_county("NV", "32")

# Combine all three into one lookup table
district_county_lookup <- bind_rows(mi, ga, nv)

# -----------------------------
# Step 5: Merge and Export
# -----------------------------

# Create a named vector to convert FIPS codes to 2-letter state abbreviations
fips_to_state <- c("26" = "MI", "13" = "GA", "32" = "NV")

# Apply conversion to standardize 'state' format across datasets
district_county_lookup <- district_county_lookup %>%
  mutate(state = fips_to_state[state])

# Fix Nevada district naming to match candidate/legislator data
district_county_lookup <- district_county_lookup %>%
  mutate(
    district_name = case_when(
      state == "NV" ~ str_replace(district_name, "Assembly", "House"),
      TRUE ~ district_name
    )
  )

# Merge county info into legislators and candidates
legislators_merged <- left_join(legislators, district_county_lookup, by = c("state", "district_name"))
candidates_merged <- left_join(candidates, district_county_lookup, by = c("state", "district_name"))

# Check how many records are missing county FIPS (should be 0 ideally)
table(is.na(legislators_merged$county_fips))
table(is.na(candidates_merged$county_fips))

# Export merged datasets to the modified_data folder, dropping geography column
write_csv(select(legislators_merged, -geometry), here("Data", "modified_data", "legislators_with_county.csv"))
write_csv(select(candidates_merged, -geometry), here("Data", "modified_data", "candidates_with_county.csv"))

# -----------------------------
# Step 6: Check for 'Missed' Counties
# -----------------------------

# Helper function: find counties in a state that were NOT assigned to any district
check_unassigned_counties <- function(state_abbr, year = 2022) {
  # All counties in the state
  all_counties <- counties(state_abbr, year = year, class = "sf") %>%
    select(county_name = NAME, county_fips = COUNTYFP) %>%
    mutate(state = state_abbr) %>%
    st_drop_geometry()
  
  # Counties used in the lookup table
  used_counties <- district_county_lookup %>%
    filter(state == state_abbr) %>%
    select(county_name, county_fips) %>%
    distinct()
  
  # Return counties that were not assigned as the primary county for any district
  anti_join(all_counties, used_counties, by = c("county_name", "county_fips"))
}

# Run the check for all three states
missing_mi <- check_unassigned_counties("MI")
missing_ga <- check_unassigned_counties("GA")
missing_nv <- check_unassigned_counties("NV")

# View results in console
missing_mi
missing_ga
missing_nv
