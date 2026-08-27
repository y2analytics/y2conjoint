# Estimate preference shares for a competitive set

Applies a logit (softmax) choice model: each respondent's utility for
every product is turned into a probability of choosing it, and those
probabilities are averaged across respondents to give each product's
mean preference share. The NONE outside good competes for share as a
"choose nothing" option and is returned as a `share_NONE` column, unless
a competitive set's `none` property is `FALSE`, in which case that set's
products are forced to compete only against one another and no
`share_NONE` column is produced for it.

## Usage

``` r
run_scenario(
  x,
  competitive_set,
  combine_fn = pmax,
  scaling_factor = 1,
  .by = NULL
)
```

## Arguments

- x:

  A
  [conjoint_df](https://y2analytics.github.io/y2conjoint/reference/conjoint_df.md)
  of individual-level utilities.

- competitive_set:

  A
  [competitive_set](https://y2analytics.github.io/y2conjoint/reference/competitive_set.md),
  or a list of them. When a list is supplied, the scenario is run on
  each set individually and the results are row-bound together, one row
  per set. A `share_*` column shared by more than one set stays a single
  column, holding `NA` for any set whose products do not include it.
  Each set's own `none` property controls whether NONE competes for
  share within that set.

- combine_fn:

  How to combine multiple selected levels within a collection. Either a
  single function applied to every collection (the default,
  [`pmax()`](https://rdrr.io/r/base/Extremes.html)), or a named list
  mapping collection names to functions. Any collection absent from the
  list falls back to [`pmax()`](https://rdrr.io/r/base/Extremes.html).

- scaling_factor:

  A numeric multiplier applied to all utilities before the softmax.
  Values above 1 sharpen the choice probabilities toward the highest
  utility; values below 1 flatten them. Defaults to `1`.

- .by:

  Optional
  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  columns to compute shares within. Each selected column is treated
  *marginally*: the sample is split by that column's values and shares
  are computed within each value, then the results for every selected
  column are stacked. Defaults to `NULL` (whole sample).

## Value

A tibble with one row per competitive set (named by the set's
`competitive_set` column, or `set_i` when unnamed) and one `share_*`
column per product, plus `share_NONE` for each set that includes the
outside good. A product not present in a given set's row is `NA` there.
When `.by` is supplied, each set instead contributes one row per
grouping variable and value, carrying `group_var` (the grouping column),
`group_level` (its value, as a string), and `n` (respondents in the
subgroup) alongside `competitive_set` and the `share_*` columns.

## Examples

``` r
cjt <- conjoint_df(example_utilities, example_crosswalk)
market <- competitive_set(
  product(cjt, c("Northwind", "$199", "20 hours", "256 GB", "Black"), name = "Value"),
  product(cjt, c("Meridian", "$399", "30 hours", "512 GB", "Black"), name = "Premium"),
  name = "Launch"
)
run_scenario(cjt, market)
#> # A tibble: 1 × 4
#>   competitive_set share_Value share_Premium share_NONE
#>   <chr>                 <dbl>         <dbl>      <dbl>
#> 1 Launch                0.597         0.243       0.16

# Sharpen the shares toward the most attractive product.
run_scenario(cjt, market, scaling_factor = 2)
#> # A tibble: 1 × 4
#>   competitive_set share_Value share_Premium share_NONE
#>   <chr>                 <dbl>         <dbl>      <dbl>
#> 1 Launch                0.715         0.197      0.088

# Shares within each region, then within each gender, stacked.
run_scenario(cjt, market, .by = c(region, gender))
#> # A tibble: 7 × 7
#>   competitive_set group_var group_level     n share_Value share_Premium
#>   <chr>           <chr>     <chr>       <int>       <dbl>         <dbl>
#> 1 Launch          region    Midwest        63       0.598         0.262
#> 2 Launch          region    Northeast      54       0.605         0.231
#> 3 Launch          region    South          47       0.58          0.259
#> 4 Launch          region    West           36       0.605         0.209
#> 5 Launch          gender    Female         97       0.617         0.232
#> 6 Launch          gender    Male           93       0.578         0.251
#> 7 Launch          gender    Nonbinary      10       0.574         0.281
#> # ℹ 1 more variable: share_NONE <dbl>

# Exclude NONE so the products are forced to compete only with each other.
forced_choice <- competitive_set(
  product(cjt, c("Northwind", "$199", "20 hours", "256 GB", "Black"), name = "Value"),
  product(cjt, c("Meridian", "$399", "30 hours", "512 GB", "Black"), name = "Premium"),
  name = "Launch",
  none = FALSE
)
run_scenario(cjt, forced_choice)
#> # A tibble: 1 × 3
#>   competitive_set share_Value share_Premium
#>   <chr>                 <dbl>         <dbl>
#> 1 Launch                0.706         0.294

# Compare two competitive sets side by side: one row per competitive set.
refresh <- competitive_set(
  product(cjt, c("Cascade", "$299", "30 hours", "512 GB", "Blue"), name = "Value"),
  name = "Refresh"
)
run_scenario(cjt, list(market, refresh))
#> # A tibble: 2 × 4
#>   competitive_set share_Value share_Premium share_NONE
#>   <chr>                 <dbl>         <dbl>      <dbl>
#> 1 Launch                0.597         0.243       0.16
#> 2 Refresh               0.7          NA           0.3 
```
