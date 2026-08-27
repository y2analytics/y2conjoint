# Protected columns of a conjoint data frame

The level columns of every collection plus the `none` column. These
columns cannot be dropped, renamed, or overwritten in place.

## Usage

``` r
protected_cols(x)
```

## Arguments

- x:

  A
  [conjoint_df](https://y2analytics.github.io/y2conjoint/reference/conjoint_df.md).

## Value

A character vector of column names.

## Examples

``` r
cjt <- conjoint_df(example_utilities, example_crosswalk)
protected_cols(cjt)
#>  [1] "Northwind" "Cascade"   "Meridian"  "$199"      "$299"      "$399"     
#>  [7] "10 hours"  "20 hours"  "30 hours"  "128 GB"    "256 GB"    "512 GB"   
#> [13] "Black"     "Silver"    "Blue"      "NONE"     
```
