# Example conjoint utilities

A small, simulated set of individual-level part-worth utilities from a
cell-phone conjoint study, in the model format (`A[NUM]B[NUM]`), used
throughout the examples and the getting-started article. The five
attributes are Brand, Price, Battery, Storage, and Color. Pass it
together with
[example_crosswalk](https://y2analytics.github.io/y2conjoint/reference/example_crosswalk.md)
to
[`conjoint_df()`](https://y2analytics.github.io/y2conjoint/reference/conjoint_df.md).

## Usage

``` r
example_utilities
```

## Format

A tibble with 200 rows and 22 columns:

- respondent_id:

  Respondent identifier.

- A1B1, A1B2, A1B3:

  Utilities for the three Brand levels.

- A2B1, A2B2, A2B3:

  Utilities for the three Price levels.

- A3B1, A3B2, A3B3:

  Utilities for the three Battery levels.

- A4B1, A4B2, A4B3:

  Utilities for the three Storage levels.

- A5B1, A5B2, A5B3:

  Utilities for the three Color levels.

- NONE:

  Utility of the outside good (choosing nothing).

- age:

  Respondent age in years.

- gender:

  Respondent gender.

- region:

  U.S. census region.

- income:

  Respondent annual income in dollars.

- education:

  Highest education completed, a `haven_labelled` variable of integer
  codes carrying value labels (as from an SPSS export).

## See also

[example_crosswalk](https://y2analytics.github.io/y2conjoint/reference/example_crosswalk.md)
