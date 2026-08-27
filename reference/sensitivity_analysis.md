# Sensitivity analysis for a product specification

Measures how a product's preference share responds to changing one level
at a time. The unchanged
[product](https://y2analytics.github.io/y2conjoint/reference/product.md)
is scored on its own (against the NONE outside good) to give a
`baseline` share, then each collection is perturbed individually - never
in combination with another collection - and re-scored:

## Usage

``` r
sensitivity_analysis(
  x,
  multiple_select,
  product,
  combine_fn = pmax,
  scaling_factor = 1
)
```

## Arguments

- x:

  A
  [conjoint_df](https://y2analytics.github.io/y2conjoint/reference/conjoint_df.md)
  of individual-level utilities.

- multiple_select:

  A character vector of collection names that may hold more than one
  level at once. Collections not listed here are treated as
  single-select.

- product:

  The
  [product](https://y2analytics.github.io/y2conjoint/reference/product.md)
  to analyse.

- combine_fn:

  How to combine multiple selected levels within a collection. Passed
  through to
  [`run_scenario()`](https://y2analytics.github.io/y2conjoint/reference/run_scenario.md).
  Either a single function applied to every collection (the default,
  [`pmax()`](https://rdrr.io/r/base/Extremes.html)), or a named list
  mapping collection names to functions.

- scaling_factor:

  A numeric multiplier applied to all utilities before the softmax.
  Passed through to
  [`run_scenario()`](https://y2analytics.github.io/y2conjoint/reference/run_scenario.md).
  Defaults to `1`.

## Value

A tibble with one row per perturbation and the columns: `Feature`
(collection name), `Level` (the level added, removed, or substituted),
`comparison` (`"added_in"`, `"taken_out"`, or `"alone"`),
`preference_share` (share of the perturbed product), `baseline` (share
of the unchanged product), `delta` (`preference_share - baseline`), and
`product_name`.

## Details

- **Single-select** collections (the default) are perturbed by replacing
  the current level with each other level in turn
  (`comparison = "alone"`).

- **Multiple-select** collections (those named in `multiple_select`) are
  perturbed by adding each not-yet-selected level
  (`comparison = "added_in"`) and, when two or more levels are already
  selected, by removing each selected level
  (`comparison = "taken_out"`).

An absence level (see
[collection](https://y2analytics.github.io/y2conjoint/reference/collection.md))
can never be paired with another level, so for a multiple-select
collection any addition that would pair with the absence level is
instead recorded as an `"alone"` swap (the candidate level on its own)
rather than an `"added_in"`.

## Examples

``` r
cjt <- conjoint_df(example_utilities, example_crosswalk)
flagship <- product(
  cjt,
  c("Northwind", "$299", "20 hours", "256 GB", "Black"),
  name = "Flagship"
)
sensitivity_analysis(cjt, multiple_select = "Brand", product = flagship)
#> # A tibble: 10 × 7
#>    Feature Level    comparison preference_share baseline   delta product_name
#>    <chr>   <chr>    <chr>                 <dbl>    <dbl>   <dbl> <chr>       
#>  1 Brand   Cascade  added_in              0.732    0.691  0.0410 Flagship    
#>  2 Brand   Meridian added_in              0.708    0.691  0.0170 Flagship    
#>  3 Price   $199     alone                 0.776    0.691  0.0850 Flagship    
#>  4 Price   $399     alone                 0.592    0.691 -0.099  Flagship    
#>  5 Battery 10 hours alone                 0.623    0.691 -0.0680 Flagship    
#>  6 Battery 30 hours alone                 0.738    0.691  0.0470 Flagship    
#>  7 Storage 128 GB   alone                 0.628    0.691 -0.0630 Flagship    
#>  8 Storage 512 GB   alone                 0.728    0.691  0.0370 Flagship    
#>  9 Color   Silver   alone                 0.663    0.691 -0.0280 Flagship    
#> 10 Color   Blue     alone                 0.646    0.691 -0.0450 Flagship    
```
