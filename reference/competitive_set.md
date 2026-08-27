# Bundle specifications into a competitive set

A `competitive_set` is an ordered list of
[product](https://y2analytics.github.io/y2conjoint/reference/product.md)s
that compete for share in a scenario. All products must reference the
same set of collections.

## Usage

``` r
competitive_set(..., name = character(), none = TRUE)
```

## Arguments

- ...:

  [product](https://y2analytics.github.io/y2conjoint/reference/product.md)
  objects that compete for share. Pass them individually; they are
  collected into the set's `products`.

- name:

  An optional single string naming the set.

- none:

  Whether the NONE outside good ("choose nothing") competes for share
  alongside the set's products. Defaults to `TRUE`. Passed through to
  [`run_scenario()`](https://y2analytics.github.io/y2conjoint/reference/run_scenario.md).

## Value

A `competitive_set` object.

## Examples

``` r
cjt <- conjoint_df(example_utilities, example_crosswalk)
competitive_set(
  product(cjt, c("Northwind", "$299", "20 hours", "256 GB", "Black"), name = "Flagship"),
  product(cjt, c("Cascade", "$199", "10 hours", "128 GB", "Blue"), name = "Budget"),
  name = "Launch"
)
#> <competitive_set> Launch: 3 products: NONE, Flagship, and Budget
#> 
#>   NONE
#> 
#>   <product> Flagship
#>   • Brand: Northwind
#>   • Price: $299
#>   • Battery: 20 hours
#>   • Storage: 256 GB
#>   • Color: Black
#> 
#>   <product> Budget
#>   • Brand: Cascade
#>   • Price: $199
#>   • Battery: 10 hours
#>   • Storage: 128 GB
#>   • Color: Blue

# Exclude the NONE outside good, forcing a choice between the products.
competitive_set(
  product(cjt, c("Northwind", "$299", "20 hours", "256 GB", "Black"), name = "Flagship"),
  product(cjt, c("Cascade", "$199", "10 hours", "128 GB", "Blue"), name = "Budget"),
  name = "Launch",
  none = FALSE
)
#> <competitive_set> Launch: 2 products: Flagship and Budget
#> 
#>   <product> Flagship
#>   • Brand: Northwind
#>   • Price: $299
#>   • Battery: 20 hours
#>   • Storage: 256 GB
#>   • Color: Black
#> 
#>   <product> Budget
#>   • Brand: Cascade
#>   • Price: $199
#>   • Battery: 10 hours
#>   • Storage: 128 GB
#>   • Color: Blue
```
