# Is a collection ordered?

Is a collection ordered?

## Usage

``` r
is_ordered(x)
```

## Arguments

- x:

  A
  [collection](https://y2analytics.github.io/y2conjoint/reference/collection.md)
  object.

## Value

A single logical.

## Examples

``` r
is_ordered(collection("Brand", c("Northwind", "Cascade")))
#> [1] FALSE
is_ordered(ordered_collection("Price", c("$199", "$299", "$399")))
#> [1] TRUE
```
