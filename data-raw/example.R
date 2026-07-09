# Generates the example datasets shipped with y2conjoint:
#   example_utilities - individual-level part-worth utilities in model format
#   example_crosswalk - maps model-format columns to collections and user names
# Run with: source("data-raw/example.R")

library(tibble)
library(haven)

set.seed(4127)

n <- 200

# Part-worth utilities. Brand levels differ in appeal; higher prices carry lower
# utility; longer battery life, more storage, and (mildly) color drive utility.
example_utilities <- tibble(
  respondent_id = seq_len(n),
  A1B1 = round(rnorm(n, 0.4, 0.5), 3), # Brand: Northwind
  A1B2 = round(rnorm(n, 0.1, 0.5), 3), # Brand: Cascade
  A1B3 = round(rnorm(n, -0.2, 0.5), 3), # Brand: Meridian
  A2B1 = round(rnorm(n, 0.5, 0.4), 3), # Price: $199
  A2B2 = round(rnorm(n, 0.0, 0.4), 3), # Price: $299
  A2B3 = round(rnorm(n, -0.5, 0.4), 3), # Price: $399
  A3B1 = round(rnorm(n, -0.3, 0.3), 3), # Battery: 10 hours
  A3B2 = round(rnorm(n, 0.1, 0.3), 3), # Battery: 20 hours
  A3B3 = round(rnorm(n, 0.4, 0.3), 3), # Battery: 30 hours
  A4B1 = round(rnorm(n, -0.2, 0.3), 3), # Storage: 128 GB
  A4B2 = round(rnorm(n, 0.1, 0.3), 3), # Storage: 256 GB
  A4B3 = round(rnorm(n, 0.3, 0.3), 3), # Storage: 512 GB
  A5B1 = round(rnorm(n, 0.1, 0.3), 3), # Color: Black
  A5B2 = round(rnorm(n, 0.0, 0.3), 3), # Color: Silver
  A5B3 = round(rnorm(n, -0.1, 0.3), 3), # Color: Blue
  NONE = round(rnorm(n, -0.3, 0.5), 3),
  age = sample(22:70, n, replace = TRUE),
  gender = sample(
    c("Female", "Male", "Nonbinary"),
    n,
    replace = TRUE,
    prob = c(0.48, 0.48, 0.04)
  ),
  region = sample(
    c("Northeast", "Midwest", "South", "West"),
    n,
    replace = TRUE
  ),
  income = round(rnorm(n, 65000, 20000) / 1000) * 1000,
  # A haven-labelled variable, as it would arrive from an SPSS export: integer
  # codes carrying value labels.
  education = labelled(
    sample(1:4, n, replace = TRUE, prob = c(0.25, 0.35, 0.28, 0.12)),
    labels = c(
      "High school" = 1,
      "Some college" = 2,
      "Bachelor's degree" = 3,
      "Graduate degree" = 4
    ),
    label = "Highest education completed"
  )
)

example_crosswalk <- tibble(
  old_name = c(
    "A1B1",
    "A1B2",
    "A1B3",
    "A2B1",
    "A2B2",
    "A2B3",
    "A3B1",
    "A3B2",
    "A3B3",
    "A4B1",
    "A4B2",
    "A4B3",
    "A5B1",
    "A5B2",
    "A5B3"
  ),
  user_name = c(
    "Northwind",
    "Cascade",
    "Meridian",
    "$199",
    "$299",
    "$399",
    "10 hours",
    "20 hours",
    "30 hours",
    "128 GB",
    "256 GB",
    "512 GB",
    "Black",
    "Silver",
    "Blue"
  ),
  collection_name = c(
    "Brand",
    "Brand",
    "Brand",
    "Price",
    "Price",
    "Price",
    "Battery",
    "Battery",
    "Battery",
    "Storage",
    "Storage",
    "Storage",
    "Color",
    "Color",
    "Color"
  ),
  collection_order = c(
    NA,
    NA,
    NA,
    1,
    2,
    3,
    1,
    2,
    3,
    1,
    2,
    3,
    NA,
    NA,
    NA
  )
)

usethis::use_data(example_utilities, example_crosswalk, overwrite = TRUE)
