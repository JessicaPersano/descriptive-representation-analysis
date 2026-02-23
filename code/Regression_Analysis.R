# -------------------------------
# Load Required Libraries
# -------------------------------
library(modelsummary)
library(tidyverse)
library(modelr)
library(here)

# Clear environment
rm(list = ls())

# -------------------------------
# Load Input Data
# -------------------------------
full_data <- read_csv(here("data", "modified_data", "full_merged_regression_dataset.csv"))
noninc_data <- read_csv(here("data", "modified_data", "nonincumbent_merged_regression_dataset.csv"))

# -------------------------------
# FULL SAMPLE ANALYSIS
# -------------------------------
# Regressions
full_race_biv <- lm(nonwhite_candidates_2024 ~ nonwhite_legislator_2022, data = full_data)
full_race_full <- lm(nonwhite_candidates_2024 ~ nonwhite_legislator_2022 + percent_nonwhite_voters + margin_of_victory, data = full_data)
full_gender_biv <- lm(women_candidates_2024 ~ woman_legislator_2022, data = full_data)
full_gender_full <- lm(women_candidates_2024 ~ woman_legislator_2022 + percent_women_voters + margin_of_victory, data = full_data)

# Plots
p1_full <- ggplot(full_data, aes(x = nonwhite_legislator_2022, y = nonwhite_candidates_2024)) +
  geom_jitter(width = 0.1, height = 0.02, alpha = 0.5) +
  geom_smooth(method = "lm", se = TRUE, color = "blue", fill = "lightblue", alpha = 0.3) +
  labs(
    title = "Bivariate Effect of Nonwhite Legislator on Nonwhite Candidates (2024) - Full Sample",
    x = "Nonwhite Legislator Elected in 2022 (0/1)",
    y = "Proportion of Nonwhite Candidates in 2024"
  )

p2_full <- ggplot(full_data, aes(x = woman_legislator_2022, y = women_candidates_2024)) +
  geom_jitter(width = 0.1, height = 0.02, alpha = 0.5) +
  geom_smooth(method = "lm", se = TRUE, color = "darkred", fill = "pink", alpha = 0.3) +
  labs(
    title = "Bivariate Effect of Woman Legislator on Women Candidates (2024) - Full Sample",
    x = "Woman Legislator Elected in 2022 (0/1)",
    y = "Proportion of Women Candidates in 2024"
  )

ggsave(here("results", "plot_full_nonwhite_legislator.png"), plot = p1_full, width = 7, height = 5)
ggsave(here("results", "plot_full_woman_legislator.png"), plot = p2_full, width = 7, height = 5)

# Table
modelsummary(
  list(
    "Nonwhite Candidates (Bivariate)" = full_race_biv,
    "Nonwhite Candidates (Full Model)" = full_race_full,
    "Women Candidates (Bivariate)" = full_gender_biv,
    "Women Candidates (Full Model)" = full_gender_full
  ),
  coef_map = c(
    "nonwhite_legislator_2022" = "Nonwhite Legislator (2022)",
    "percent_nonwhite_voters" = "% Nonwhite Voters",
    "margin_of_victory" = "Margin of Victory",
    "woman_legislator_2022" = "Woman Legislator (2022)",
    "percent_women_voters" = "% Women Voters"
  ),
  stars = TRUE,
  statistic = "std.error",
  gof_omit = "IC|Log",
  output = here("results", "regression_table_full.html"),
  title = "Effect of 2022 Legislator Diversity on 2024 Candidate Pool - Full Sample"
)

# -------------------------------
# NON-INCUMBENT SAMPLE ANALYSIS
# -------------------------------
# Regressions
noninc_race_biv <- lm(nonwhite_candidates_2024 ~ nonwhite_legislator_2022, data = noninc_data)
noninc_race_full <- lm(nonwhite_candidates_2024 ~ nonwhite_legislator_2022 + percent_nonwhite_voters + margin_of_victory, data = noninc_data)
noninc_gender_biv <- lm(women_candidates_2024 ~ woman_legislator_2022, data = noninc_data)
noninc_gender_full <- lm(women_candidates_2024 ~ woman_legislator_2022 + percent_women_voters + margin_of_victory, data = noninc_data)

# Plots
p1_noninc <- ggplot(noninc_data, aes(x = nonwhite_legislator_2022, y = nonwhite_candidates_2024)) +
  geom_jitter(width = 0.1, height = 0.02, alpha = 0.5) +
  geom_smooth(method = "lm", se = TRUE, color = "blue", fill = "lightblue", alpha = 0.3) +
  labs(
    title = "Bivariate Effect of Nonwhite Legislator on Nonwhite Candidates (2024) - Non-Incumbent Sample",
    x = "Nonwhite Legislator Elected in 2022 (0/1)",
    y = "Proportion of Nonwhite Candidates in 2024"
  )

p2_noninc <- ggplot(noninc_data, aes(x = woman_legislator_2022, y = women_candidates_2024)) +
  geom_jitter(width = 0.1, height = 0.02, alpha = 0.5) +
  geom_smooth(method = "lm", se = TRUE, color = "darkred", fill = "pink", alpha = 0.3) +
  labs(
    title = "Bivariate Effect of Woman Legislator on Women Candidates (2024) - Non-Incumbent Sample",
    x = "Woman Legislator Elected in 2022 (0/1)",
    y = "Proportion of Women Candidates in 2024"
  )

ggsave(here("results", "plot_noninc_nonwhite_legislator.png"), plot = p1_noninc, width = 7, height = 5)
ggsave(here("results", "plot_noninc_woman_legislator.png"), plot = p2_noninc, width = 7, height = 5)

# Table
modelsummary(
  list(
    "Nonwhite Candidates (Bivariate)" = noninc_race_biv,
    "Nonwhite Candidates (Full Model)" = noninc_race_full,
    "Women Candidates (Bivariate)" = noninc_gender_biv,
    "Women Candidates (Full Model)" = noninc_gender_full
  ),
  coef_map = c(
    "nonwhite_legislator_2022" = "Nonwhite Legislator (2022)",
    "percent_nonwhite_voters" = "% Nonwhite Voters",
    "margin_of_victory" = "Margin of Victory",
    "woman_legislator_2022" = "Woman Legislator (2022)",
    "percent_women_voters" = "% Women Voters"
  ),
  stars = TRUE,
  statistic = "std.error",
  gof_omit = "IC|Log",
  output = here("results", "regression_table_nonincumbent.html"),
  title = "Effect of 2022 Legislator Diversity on 2024 Candidate Pool - Non-Incumbent Sample"
)
