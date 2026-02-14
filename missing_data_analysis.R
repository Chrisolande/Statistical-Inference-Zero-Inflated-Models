# Missing Data Analysis Script

library(dplyr)
library(tidyr)
library(ggplot2)
library(lubridate)
library(naniar)
library(purrr)
library(glue)
library(viridis)

df <- readr::read_csv(here::here("data", "weatherAUS.csv")) %>%
  janitor::clean_names()

# High Missing cols
high_miss_cols <- c("sunshine", "evaporation", "cloud3pm", "cloud9am")

# Confirm theyre in the df
high_miss <- high_miss_cols[high_miss_cols %in% names(df)]

cat("High missingness variables:", paste(high_miss, collapse = ", "), "\n\n")


# Analyze Co-missingness Patterns
cat("Analyzing co-missingness patterns...\n")

# logical matrix (TRUE = Missing)
miss_mat <- df %>%
  select(all_of(high_miss)) %>%
  mutate(across(everything(), is.na)) %>%
  as.matrix() %>%
  apply(2, as.integer) # Convert TRUE/FALSE to 1/0

# calculate intersections (Matrix Multiplication)

intersection_matrix <- crossprod(miss_mat)

# get individual missing counts (the diagonal of the matrix)
total_miss_counts <- diag(intersection_matrix)

# calculate Conditional Probabilities
# "Given ROW (var1) is missing, what % of the time is COL (var2) missing?"

pct_matrix <- intersection_matrix / total_miss_counts * 100

co_missing_stats <- as.data.frame(as.table(pct_matrix)) %>%
  rename(var1 = Var1, var2 = Var2, pct_co_miss = Freq) %>%
  filter(var1 != var2) %>% # Remove self-matches
  arrange(desc(pct_co_miss))

print(co_missing_stats)

co_missing_stats %>%
  mutate(
    msg = glue(
      "  {var1} -> {var2}: {round(pct_co_miss, 1)}% (When {var1} is missing, {var2} is missing)"
    )
  ) %>%
  pull(msg) %>%
  walk(cat, "\n")
cat("\n")


# Missing Pattern Combinations
cat("Missing pattern combinations (Top 10):\n")
df %>%
  select(all_of(high_miss)) %>%
  miss_case_table() %>%
  head(10) %>%
  print()

# Analyze Missingness by Location -
cat("\nAnalyzing missingness by location...\n")

location_summary <- df %>%
  group_by(location) %>%
  miss_var_summary()

location_summary %>%
  filter(variable %in% high_miss) %>%
  arrange(desc(pct_miss)) %>%
  head(10) %>%
  print()

cat("\n")


# Analyze Temporal Trends in Missingness
cat("Analyzing temporal trends...\n")

temporal_trend <- df %>%
  mutate(month = floor_date(date, "month")) %>%
  select(month, any_of(high_miss)) %>%
  pivot_longer(cols = -month, names_to = "variable", values_to = "value") %>%
  group_by(month, variable) %>%
  summarise(pct_missing = mean(is.na(value)) * 100, .groups = "drop")

# Plot temporal trends
p_time <- ggplot(
  temporal_trend,
  aes(x = month, y = pct_missing, color = variable)
) +
  geom_line(linewidth = 1) +
  facet_wrap(~variable, scales = "free_y", ncol = 1) +
  labs(
    title = "Timeline of Systematic Missingness",
    subtitle = "Notice the structural breaks in data collection",
    y = "Missingness (%)",
    x = "Year"
  ) +
  theme_minimal() +
  scale_y_continuous(limits = c(0, 100))

print(p_time)


# Sunshine vs. Rainfall Analysis
if (all(c("rainfall", "sunshine") %in% names(df))) {
  cat("\nRunning Sunshine vs Rainfall check...\n")

  # Calculate sunshine missingness by rainfall status
  weather_missing_stats <- df %>%
    filter(!is.na(rainfall)) %>% # Remove rows where rainfall itself is unknown
    mutate(is_rainy = if_else(rainfall > 1, "Rainy (>1mm)", "Dry (≤1mm)")) %>%
    group_by(is_rainy) %>%
    summarise(
      n_obs = n(),
      pct_sunshine_missing = mean(is.na(sunshine)) * 100,
      .groups = "drop"
    )

  print(weather_missing_stats)

  # Plot rainfall density by sunshine missingness
  p_rainfall <- df %>%
    bind_shadow() %>%
    filter(rainfall > 0 & rainfall < 50) %>%
    ggplot(aes(x = rainfall, fill = sunshine_NA)) +
    geom_density(alpha = 0.6) +
    scale_fill_viridis_d(labels = c("!NA" = "Present", "NA" = "Missing")) +
    labs(
      title = "Does Sunshine go missing on rainy days?",
      subtitle = "Density of rainfall amounts for Missing vs. Present sunshine data",
      x = "Rainfall (mm)",
      y = "Density",
      fill = "Sunshine Status"
    ) +
    theme_minimal()

  print(p_rainfall)
}
