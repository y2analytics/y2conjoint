# Collections of conjoint levels

A collection groups the columns of a
[conjoint_df](https://y2analytics.github.io/y2conjoint/reference/conjoint_df.md)
that belong to a single conjoint attribute (e.g. all `Brand` levels). An
`ordered_collection` is a collection whose levels have a meaningful
order; the order is recorded by the order of `levels` (there is no
enforcement of that order elsewhere yet).

## Usage

``` r
collection(name = character(0), levels = character(0), absence = character(0))

ordered_collection(
  name,
  levels,
  order = unique(levels),
  absence = character(0)
)
```

## Arguments

- name:

  A single string naming the collection.

- levels:

  A character vector of the level (column) names that make up the
  collection.

- absence:

  An optional single level name marking the "absence" level of the
  collection, the level that represents having none of the feature. It
  must be one of `levels`. Defaults to `character(0)` (no absence
  level).

- order:

  For `ordered_collection`, a character vector giving the levels in
  their intended order. It must contain exactly the same levels as
  `levels`. Defaults to `unique(levels)`, i.e. the order in which
  `levels` were supplied.

## Value

A `collection` or `ordered_collection` object.

## Details

Use `absence` when one level means the attribute is not present at all
and the remaining levels are versions of the feature (e.g. `"No camera"`
alongside `"8 MP"` and `"12 MP"`). Leave it empty when every level is a
real option, such as brands, where no level means "no brand". `absence`
is a label only and does not change the order of the levels.

Use `ordered_collection()` with `order` when the levels have a natural
ranking that matters for interpretation or display, such as price,
storage, or speed, and `levels` is not already listed in that sequence.
Use `collection()` for nominal attributes with no meaningful ranking. If
the absence level is the lowest-ranked option, place it first in
`order`.

## Examples

``` r
collection(name = "Brand", levels = c("Northwind", "Cascade"))
#> <collection> Brand
#> • Northwind
#> • Cascade

# Flag the level that represents having none of the feature.
collection(
  name = "Camera",
  levels = c("No camera", "8 MP", "12 MP"),
  absence = "No camera"
)
#> <collection> Camera
#> • No camera (absence)
#> • 8 MP
#> • 12 MP

# By default the level order is taken from `levels`.
ordered_collection(name = "Price", levels = c("$199", "$299", "$399"))
#> <collection> Price (ordered)
#> • $199
#> • $299
#> • $399

# Supply `order` to rank levels independently of how they were listed.
ordered_collection(
  name = "Price",
  levels = c("$399", "$199", "$299"),
  order = c("$199", "$299", "$399")
)
#> <collection> Price (ordered)
#> • $199
#> • $299
#> • $399
```
