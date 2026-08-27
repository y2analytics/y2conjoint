# Example conjoint crosswalk

The crosswalk that maps the model-format columns of
[example_utilities](https://y2analytics.github.io/y2conjoint/reference/example_utilities.md)
to their collections and user-facing level names.

## Usage

``` r
example_crosswalk
```

## Format

A tibble with 15 rows and 4 columns:

- old_name:

  Model-format column name (`A[NUM]B[NUM]`).

- user_name:

  User-facing level name.

- collection_name:

  Collection (attribute) the level belongs to.

- collection_order:

  Integer rank for ordered collections, `NA` otherwise.

## See also

[example_utilities](https://y2analytics.github.io/y2conjoint/reference/example_utilities.md)
