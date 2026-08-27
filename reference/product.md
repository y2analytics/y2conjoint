# Define a product specification

A `product` records the levels that make up a single product, grouped by
collection. It is built from a flat vector of user-facing level names
(any subset is allowed, including selecting several levels from one
collection); the levels are validated against, and grouped by, the
collections of `x`.

## Usage

``` r
product(x, levels, name = character())
```

## Arguments

- x:

  A
  [conjoint_df](https://y2analytics.github.io/y2conjoint/reference/conjoint_df.md)
  or a list of
  [collection](https://y2analytics.github.io/y2conjoint/reference/collection.md)s
  to validate against.

- levels:

  A character vector of user-facing level names.

- name:

  An optional single string naming the product.

## Value

A `product` object.

## Examples

``` r
cjt <- conjoint_df(example_utilities, example_crosswalk)

# Select one level per collection.
product(cjt, c("Northwind", "$299", "20 hours", "256 GB", "Black"), name = "Flagship")
#> <product> Flagship
#> • Brand: Northwind
#> • Price: $299
#> • Battery: 20 hours
#> • Storage: 256 GB
#> • Color: Black

# Selecting several brands models a co-branded product.
product(
  cjt,
  c("Northwind", "Cascade", "$199", "10 hours", "128 GB", "Blue"),
  name = "Co-brand"
)
#> <product> Co-brand
#> • Brand: Northwind and Cascade
#> • Price: $199
#> • Battery: 10 hours
#> • Storage: 128 GB
#> • Color: Blue

# Any subset is allowed; omitted collections warn and contribute no utility.
product(cjt, c("Meridian", "$399"), name = "Sparse")
#> Warning: No levels selected for collections Battery, Storage, and Color.
#> <product> Sparse
#> • Brand: Meridian
#> • Price: $399
#> • Battery: —
#> • Storage: —
#> • Color: —
```
