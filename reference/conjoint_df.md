# Create a conjoint data frame

`conjoint_df()` builds a tibble subclass that carries its conjoint
structure as metadata. Utility columns arrive in the model format
(`A[NUM]B[NUM]`) and are renamed to their user-facing names; they are
grouped into
[collection](https://y2analytics.github.io/y2conjoint/reference/collection.md)s
via the supplied `crosswalk`. Any columns not described by the crosswalk
(e.g. demographics or IDs) are kept as-is.

## Usage

``` r
conjoint_df(data, crosswalk, none_col = "NONE")
```

## Arguments

- data:

  A data frame of individual-level utilities. Level columns are named in
  the model format `A[NUM]B[NUM]`; extra columns are allowed. It is
  coerced to a tibble internally.

- crosswalk:

  A data frame mapping levels to collections, with columns `old_name`
  (the model-format column), `user_name` (the renamed column),
  `collection_name`, and `collection_order` (an integer rank, or `NA`
  for unordered collections). An optional logical `absence` column flags
  the "absence" level of a collection (see
  [collection](https://y2analytics.github.io/y2conjoint/reference/collection.md));
  at most one level per collection may be flagged, and it defaults to no
  absence levels when the column is missing. It is coerced to a tibble
  internally, which gives stricter column access (no partial matching)
  than a base data frame.

- none_col:

  The name of the outside-good column. Defaults to `"NONE"`.

## Value

A `conjoint_df`.

## Details

The level columns and the `none` column are *protected*: dplyr and base
operations may freely edit other columns, but attempts to drop, rename,
or overwrite a protected column error. Convert with
[`tibble::as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
first to escape those guards.

## Examples

``` r
conjoint_df(example_utilities, example_crosswalk)
#> <conjoint_df>: 5 collections
#>   • Brand
#>   • Price (ordered)
#>   • Battery (ordered)
#>   • Storage (ordered)
#>   • Color
#> NONE = NONE, 6 extra columns
#> # A tibble: 200 × 22
#>    respondent_id Northwind Cascade Meridian `$199` `$299` `$399` `10 hours`
#>            <int>     <dbl>   <dbl>    <dbl>  <dbl>  <dbl>  <dbl>      <dbl>
#>  1             1    -0.178   0.362    0.042  0.596 -0.573 -1.05      -0.387
#>  2             2     0.909   0.303   -0.792  0.409  0.369 -1.47      -0.468
#>  3             3    -0.26   -0.82     0.044  0.188  0.151 -0.311     -0.401
#>  4             4    -0.062   0.226   -0.372  0.463  0.161 -0.248     -0.265
#>  5             5     0.292   0.46    -0.848  0.946  0.26  -1.23      -0.419
#>  6             6     0.382   0.65    -0.15   0.353  0.399 -0.466     -0.187
#>  7             7     0.095  -0.429    0.584  0.556  0.2    0.239     -0.74 
#>  8             8     0.803   0.588   -0.297  1.31   0.307 -0.423     -0.647
#>  9             9     0.249   1.62    -0.262  0.656 -0.136 -0.5       -0.608
#> 10            10     0.23   -0.212   -1.30   0.549 -0.666 -0.428     -0.473
#> # ℹ 190 more rows
#> # ℹ 14 more variables: `20 hours` <dbl>, `30 hours` <dbl>, `128 GB` <dbl>,
#> #   `256 GB` <dbl>, `512 GB` <dbl>, Black <dbl>, Silver <dbl>, Blue <dbl>,
#> #   NONE <dbl>, age <int>, gender <chr>, region <chr>, income <dbl>,
#> #   education <int+lbl>
```
