# PS170A: Descriptive Representation and Candidate Emergence

This repository contains the data and R code for our PS170A final project, which analyzes whether the demographic characteristics of state legislators elected in 2022 influenced the demographic composition of candidate pools in 2024 state house races.

## Research Question

Does electing legislators from underrepresented groups (women and non-white individuals) lead to more diverse candidate pools in subsequent elections? This study examines state house districts in Georgia, Michigan, and Nevada to test theories of descriptive representation and candidate emergence.

## Project Structure

```
PS170A/
├── code/                                      # Analysis scripts (run in order)
│   ├── 1_County_FIPS_Extraction.R             # Assigns counties to districts
│   ├── 2_Census_Demographic_Data.R            # Pulls district demographics from Census
│   ├── 3_Race_Gender_Algorithm.R              # Predicts race/gender of candidates
│   ├── 4_Candidate_Demographic_Percentages.R  # Aggregates candidate demographics
│   ├── 5_Final_Merge.R                        # Merges all datasets
│   ├── 6_Regression_Analysis.R                # Runs regression models
│   └── Random_Sample.R                        # Validation sampling
├── data/
│   ├── original_data/                         # Raw input data
│   └── modified_data/                         # Processed intermediate files
├── results/                                   # Regression tables and plots
│   ├── plot_full_nonwhite_legislator.png
│   ├── plot_full_woman_legislator.png
│   ├── plot_noninc_nonwhite_legislator.png
│   ├── plot_noninc_woman_legislator.png
│   ├── regression_table_full.pdf
│   ├── regression_table_nonincumbent.pdf      
├── .Renviron.example                          # Template for API keys
└── PS170A_Descriptive_Representation.pdf      # Final paper (PDF)
└── PS170A_Final_Poster.pdf                    # Final presentation (PDF)
└── install_packages.R                         # R package installation script                                                      
                              
```

plot_full_nonwhite_legislator.png
Reorganize project: rename folders to lowercase, move results to top …
1 minute ago
plot_full_woman_legislator.png
Reorganize project: rename folders to lowercase, move results to top …
1 minute ago
plot_noninc_nonwhite_legislator.png
Reorganize project: rename folders to lowercase, move results to top …
1 minute ago
plot_noninc_woman_legislator.png
Reorganize project: rename folders to lowercase, move results to top …
1 minute ago
regression_table_full.pdf
Reorganize project: rename folders to lowercase, move results to top …
1 minute ago
regression_table_nonincumbent.pdf

## Setup Instructions

### 1. Install Required R Packages

The easiest way is to run the provided installation script:

```r
source("install_packages.R")
```

Or install manually:

```r
# Install CRAN packages
install.packages(c(
  "tidyverse",
  "here",
  "wru",
  "tidycensus",
  "sf",
  "tigris",
  "readxl",
  "writexl",
  "modelsummary",
  "modelr",
  "devtools"
))

# Install genderizeR from GitHub (archived from CRAN)
devtools::install_github("kalimu/genderizeR")
```

**Note:** The `genderizeR` package was archived from CRAN and must be installed from GitHub.

### 2. Configure API Keys

This project requires two API keys:

1. **Genderize.io API Key** - For gender prediction from first names
   - Sign up at: https://genderize.io

2. **Census API Key** - For pulling demographic data and WRU race prediction
   - Sign up at: https://api.census.gov/data/key_signup.html

To configure:

1. Copy `.Renviron.example` to `.Renviron` in the project root
2. Add your API keys to the `.Renviron` file:
   ```
   GENDERIZE_API_KEY=your_key_here
   CENSUS_API_KEY=your_key_here
   ```
3. Restart R for changes to take effect

**Important:** Never commit your `.Renviron` file to version control.

### 3. Set Up the `here` Package

The scripts use the `here` package for portable file paths. Before running:

1. Open R in the project root directory
2. Run `here::here()` to verify it points to the correct location
3. If needed, create a `.here` file or `.Rproj` file in the root to anchor the project

## Running the Analysis

Execute the R scripts in the following order:

1. **County_FIPS_Extraction.R** - Downloads shapefiles and assigns each district to its primary county
2. **Census_Demographic_Data.R** - Pulls district-level race and gender demographics from the Census ACS
3. **Race_Gender_Algorithm.R** - Predicts race and gender for all candidates and legislators using genderize.io and WRU BISG
4. **Candidate_Demographic_Percentages.R** - Calculates the percentage of non-white and female candidates per district
5. **Final_Merge.R** - Merges legislator data, candidate data, competitiveness, and demographics
6. **Regression_Analysis.R** - Runs OLS regression models and generates output tables/plots

## Data Sources

- **Candidate/Legislator Data**: State election records for GA, MI, NV
- **District Competitiveness**: Election margin of victory data
- **District Demographics**: American Community Survey (ACS) 5-year estimates (2022)
- **Geographic Data**: TIGER/Line Shapefiles from U.S. Census Bureau

## Methodology

- **Gender Prediction**: Uses the genderize.io API based on first names
- **Race Prediction**: Uses the WRU package's Bayesian Improved Surname Geocoding (BISG) method, incorporating surname, geography, and party registration
- **Statistical Analysis**: OLS regression with controls for district demographics and electoral competitiveness

## Output

The analysis produces:
- Regression tables comparing bivariate and full models (HTML format)
- Scatter plots with regression lines showing the relationship between legislator diversity and candidate pool diversity
- Separate analyses for full sample and non-incumbent candidates only

## Authors

- Jessica Persano
- Xuanting Fan
- Jolie Anderson

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- UCLA Political Science Department (PS 170A)
- U.S. Census Bureau for demographic data
- genderize.io for gender prediction API
- Authors of the `wru` package for race prediction methodology
