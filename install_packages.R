# ============================================
# Install Required R Packages
# ============================================
# Run this script once before running the analysis
# to install all required packages.

# List of required packages from CRAN
required_packages <- c(
  # Core tidyverse packages
  "tidyverse",      # Includes dplyr, readr, ggplot2, tidyr, stringr, etc.

  # File path management
  "here",           # Portable file paths that work across systems

  # Demographic prediction
  # NOTE: genderizeR is installed separately from GitHub (see below)
  "wru",            # Race prediction using BISG method

  # Census data access
  "tidycensus",     # Pull Census/ACS data (requires API key)

  # Geospatial analysis
  "sf",             # Simple features for spatial data
  "tigris",         # Download Census TIGER shapefiles

  # Excel file handling
  "readxl",         # Read Excel files
  "writexl",        # Write Excel files

  # Regression output
  "modelsummary",   # Create publication-ready regression tables
  "modelr"          # Model helper functions
)

# Function to install missing packages
install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(new_packages) > 0) {
    message("Installing: ", paste(new_packages, collapse = ", "))
    install.packages(new_packages)
  } else {
    message("All packages are already installed.")
  }
}

# Install missing packages
install_if_missing(required_packages)

# ============================================
# Install genderizeR from GitHub
# ============================================
# genderizeR was archived from CRAN but is still available on GitHub
# This package is required for gender prediction from first names

if (!requireNamespace("genderizeR", quietly = TRUE)) {
  message("\nInstalling genderizeR from GitHub (archived from CRAN)...")
  if (!requireNamespace("devtools", quietly = TRUE)) {
    install.packages("devtools")
  }
  devtools::install_github("kalimu/genderizeR")
} else {
  message("genderizeR is already installed.")
}

# All packages to verify (including GitHub packages)
all_packages <- c(required_packages, "genderizeR")

# Load all packages to verify installation
message("\nVerifying package installation...")
for (pkg in all_packages) {
  if (require(pkg, character.only = TRUE, quietly = TRUE)) {
    message("  OK: ", pkg)
  } else {
    warning("  FAILED: ", pkg)
  }
}

message("\n============================================")
message("Package installation complete!")
message("============================================")
message("\nNext steps:")
message("1. Copy .Renviron.example to .Renviron")
message("2. Add your API keys to .Renviron:")
message("   - GENDERIZE_API_KEY from https://genderize.io")
message("   - CENSUS_API_KEY from https://api.census.gov/data/key_signup.html")
message("3. Restart R for the environment variables to take effect")
