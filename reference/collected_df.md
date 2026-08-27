# A data frame carrying collections of columns

A `collected_df` is a tibble subclass that carries a list of
[collection](https://y2analytics.github.io/y2conjoint/reference/collection.md)s
as metadata: each collection names a group of columns that belong
together. It is the base type behind
[conjoint_df](https://y2analytics.github.io/y2conjoint/reference/conjoint_df.md)
(which adds an outside-good column and column protection).

## Usage

``` r
collected_df(data, collections)
```

## Arguments

- data:

  A data frame. It is coerced to a tibble internally.

- collections:

  The
  [collection](https://y2analytics.github.io/y2conjoint/reference/collection.md)s
  that group the columns of `data`. Accepts a single
  [collection](https://y2analytics.github.io/y2conjoint/reference/collection.md),
  a vector of them (via [`c()`](https://rdrr.io/r/base/c.html)), or a
  list. Every level of every collection must be a column of `data`.

## Value

A `collected_df`.

## Details

Unlike a `conjoint_df`, a plain `collected_df` does not protect its
columns: ordinary dplyr and base operations may freely edit them. The
class is preserved through dplyr verbs where possible; if an operation
removes some of a collection's columns, that collection is dropped (with
a warning) rather than left dangling.

## Examples

``` r
shares <- tibble::tibble(share_A = 0.4, share_B = 0.6)

# A single collection need not be wrapped in a list.
collected_df(shares, collection("Launch", c("share_A", "share_B")))
#> <collected_df>: 1 collection
#> • Launch
#> # A tibble: 1 × 2
#>   share_A share_B
#>     <dbl>   <dbl>
#> 1     0.4     0.6

# Several collections can be passed as a vector or a list.
two <- tibble::tibble(share_A = 0.4, share_B = 0.6)
collected_df(two, c(collection("A", "share_A"), collection("B", "share_B")))
#> <collected_df>: 2 collections
#> • A
#> • B
#> # A tibble: 1 × 2
#>   share_A share_B
#>     <dbl>   <dbl>
#> 1     0.4     0.6
```
