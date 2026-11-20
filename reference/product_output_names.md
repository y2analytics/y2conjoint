# Product names

Names each product after its own name, falling back to a positional name
(`product_1`, `product_2`, ...) for unnamed products. These match the
`share_*` columns returned by
[`run_scenario()`](https://y2analytics.github.io/y2conjoint/reference/run_scenario.md).

## Usage

``` r
product_output_names(products)
```

## Arguments

- products:

  A
  [competitive_set](https://y2analytics.github.io/y2conjoint/reference/competitive_set.md),
  a single
  [product](https://y2analytics.github.io/y2conjoint/reference/product.md),
  or a list of
  [product](https://y2analytics.github.io/y2conjoint/reference/product.md)s.

## Value

A character vector with one name per product, in order. `NONE` is not
included.

## Examples

``` r
cjt <- conjoint_df(example_utilities, example_crosswalk)
flagship <- product(
  cjt,
  c("Northwind", "$299", "20 hours", "256 GB", "Black"),
  name = "Flagship"
)
budget <- product(cjt, c("Cascade", "$199", "10 hours", "128 GB", "Blue"))

product_output_names(flagship)
#> [1] "Flagship"
product_output_names(list(flagship, budget))
#> [1] "Flagship"  "product_2"
product_output_names(competitive_set(flagship, budget))
#> [1] "Flagship"  "product_2"
```
