# The collections of a collected data frame

Returns the list of
[collection](https://y2analytics.github.io/y2conjoint/reference/collection.md)s
carried by a
[collected_df](https://y2analytics.github.io/y2conjoint/reference/collected_df.md)
(including a
[conjoint_df](https://y2analytics.github.io/y2conjoint/reference/conjoint_df.md),
which is a `collected_df`). Each collection names a group of columns
that belong together - for example, the conjoint attributes of a
`conjoint_df`.

## Usage

``` r
get_collections(x, call = rlang::caller_env())
```

## Arguments

- x:

  A
  [collected_df](https://y2analytics.github.io/y2conjoint/reference/collected_df.md).

- call:

  The calling environment, used to report errors. Defaults to the caller
  of `get_collections()`.

## Value

A list of
[collection](https://y2analytics.github.io/y2conjoint/reference/collection.md)
objects.

## Examples

``` r
# A conjoint_df carries one collection per attribute.
cjt <- conjoint_df(example_utilities, example_crosswalk)
get_collections(cjt)
#> [[1]]
#> <collection> Brand
#>   • Northwind
#>   • Cascade
#>   • Meridian
#> 
#> [[2]]
#> <collection> Price (ordered)
#>   • $199
#>   • $299
#>   • $399
#> 
#> [[3]]
#> <collection> Battery (ordered)
#>   • 10 hours
#>   • 20 hours
#>   • 30 hours
#> 
#> [[4]]
#> <collection> Storage (ordered)
#>   • 128 GB
#>   • 256 GB
#>   • 512 GB
#> 
#> [[5]]
#> <collection> Color
#>   • Black
#>   • Silver
#>   • Blue
#> 
```
