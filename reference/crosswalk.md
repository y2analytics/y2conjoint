# Crosswalks: mapping model columns to collections

A crosswalk is a data frame that tells
[`conjoint_df()`](https://y2analytics.github.io/y2conjoint/reference/conjoint_df.md)
how the model-format columns of a utilities data frame map to
user-facing level names and to the
[collection](https://y2analytics.github.io/y2conjoint/reference/collection.md)s
(conjoint attributes) they belong to.

## Details

Each row of a crosswalk describes one level column:

- `old_name`: the model-format column name, `A[NUM]B[NUM]`, as it
  appears in the utilities data.

- `user_name`: the name the column takes after
  [`conjoint_df()`](https://y2analytics.github.io/y2conjoint/reference/conjoint_df.md)
  renames it. Must be unique across the crosswalk.

- `collection_name`: the attribute the level belongs to, e.g. `"Brand"`.

- `collection_order`: an integer rank giving the level's position in an
  ordered collection, or `NA` for an unordered collection. A collection
  must be either fully ranked or fully `NA`; partial ranks are an error.

- `absence` (optional): a logical flag marking the level that means the
  attribute is absent (see
  [collection](https://y2analytics.github.io/y2conjoint/reference/collection.md)).
  At most one level per collection may be flagged. If the column is
  missing, no level is treated as absence.

All of `old_name`, `user_name`, and `collection_name` must be character.
Every `old_name` must be a column of the utilities data, and each
`old_name` may appear only once. Columns of the utilities data that are
not listed in the crosswalk (e.g. IDs or demographics) are left
unchanged.

The crosswalk is coerced to a tibble, so `$` and `[[` do not partially
match column names.

## See also

[`conjoint_df()`](https://y2analytics.github.io/y2conjoint/reference/conjoint_df.md)
builds a conjoint data frame from a crosswalk,
[collection](https://y2analytics.github.io/y2conjoint/reference/collection.md)
and
[`ordered_collection()`](https://y2analytics.github.io/y2conjoint/reference/collection.md)
describe the collections it creates, and
[example_crosswalk](https://y2analytics.github.io/y2conjoint/reference/example_crosswalk.md)
is a worked example.

## Examples

``` r
head(example_crosswalk)
#> # A tibble: 6 × 4
#>   old_name user_name collection_name collection_order
#>   <chr>    <chr>     <chr>                      <dbl>
#> 1 A1B1     Northwind Brand                         NA
#> 2 A1B2     Cascade   Brand                         NA
#> 3 A1B3     Meridian  Brand                         NA
#> 4 A2B1     $199      Price                          1
#> 5 A2B2     $299      Price                          2
#> 6 A2B3     $399      Price                          3

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
