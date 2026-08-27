# Compute the total utility of a product

A product is described by a
[product](https://y2analytics.github.io/y2conjoint/reference/product.md),
which selects one or more levels from each collection (attribute). This
function turns that description into a single utility per respondent by:

1.  combining the selected levels *within* each collection into one
    value (e.g. [`pmax()`](https://rdrr.io/r/base/Extremes.html) takes
    the best available level, which is how co-branded products that list
    two brands are handled), and

2.  summing those per-collection values *across* collections.

## Usage

``` r
compute_product_utility(x, product, combine_fn = pmax)
```

## Arguments

- x:

  A
  [conjoint_df](https://y2analytics.github.io/y2conjoint/reference/conjoint_df.md).

- product:

  A
  [product](https://y2analytics.github.io/y2conjoint/reference/product.md).

- combine_fn:

  How to combine multiple selected levels within a collection. Either a
  single function applied to every collection (the default,
  [`pmax()`](https://rdrr.io/r/base/Extremes.html)), or a named list
  mapping collection names to functions. Any collection absent from the
  list falls back to [`pmax()`](https://rdrr.io/r/base/Extremes.html).

## Value

A numeric vector, one utility per row of `x`.

## Examples

``` r
cjt <- conjoint_df(example_utilities, example_crosswalk)
flagship <- product(
  cjt,
  c("Northwind", "$299", "20 hours", "256 GB", "Black"),
  name = "Flagship"
)
head(compute_product_utility(cjt, flagship))
#> [1] -0.701  1.398  0.282  0.218  1.305  0.965

# Sum the brand levels of a co-branded product instead of taking the best.
co_brand <- product(
  cjt,
  c("Northwind", "Cascade", "$199", "20 hours", "256 GB", "Black")
)
head(compute_product_utility(cjt, co_brand, combine_fn = list(Brand = `+`)))
#> [1]  0.830  1.741 -0.501  0.746  2.451  1.569
```
