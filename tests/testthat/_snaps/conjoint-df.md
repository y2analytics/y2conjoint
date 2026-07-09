# conjoint_df errors when a crosswalk level is missing from data

    Code
      conjoint_df(sample_data(), crosswalk)
    Condition
      Error in `conjoint_df()`:
      x `crosswalk` maps column A9B9 that is not in `data`.
      ! Every old_name must name a column of `data`.

# conjoint_df errors on duplicate user names

    Code
      conjoint_df(sample_data(), crosswalk)
    Condition
      Error in `conjoint_df()`:
      x user_name values in `crosswalk` must be unique.
      ! Duplicated: Northwind.

# conjoint_df errors when one old_name maps to multiple collections

    Code
      conjoint_df(sample_data(), crosswalk)
    Condition
      Error in `conjoint_df()`:
      x Each old_name in `crosswalk` must map to one collection.
      ! Assigned more than once: A1B1.

# conjoint_df errors when a user_name collides with an existing column

    Code
      conjoint_df(sample_data(), crosswalk)
    Condition
      Error in `conjoint_df()`:
      x user_name value age would collide with existing column of `data`.
      ! Renaming would create duplicate columns.
      i Pick names that are not already columns of `data`.

# conjoint_df errors when the NONE column is absent

    Code
      conjoint_df(data, sample_crosswalk())
    Condition
      Error in `conjoint_df()`:
      x `none` column NONE is not in `data`.
      i Set `none` to the name of your outside-good column.

# conjoint_df errors on a partial collection order

    Code
      conjoint_df(sample_data(), crosswalk)
    Condition
      Error in `conjoint_df()`:
      x Collection Price has a partial collection_order.
      ! Ordered collections need a rank for every level.
      i Give every level an order, or set them all to NA.

# conjoint_df prints a structure header

    Code
      print(sample_conjoint())
    Output
      <conjoint_df>: 5 collections
        * Brand
        * Price (ordered)
        * Battery (ordered)
        * Storage (ordered)
        * Color
      NONE = NONE, 6 extra columns
      # A tibble: 200 x 22
         respondent_id Northwind Cascade Meridian `$199` `$299` `$399` `10 hours`
                 <int>     <dbl>   <dbl>    <dbl>  <dbl>  <dbl>  <dbl>      <dbl>
       1             1    -0.178   0.362    0.042  0.596 -0.573 -1.05      -0.387
       2             2     0.909   0.303   -0.792  0.409  0.369 -1.47      -0.468
       3             3    -0.26   -0.82     0.044  0.188  0.151 -0.311     -0.401
       4             4    -0.062   0.226   -0.372  0.463  0.161 -0.248     -0.265
       5             5     0.292   0.46    -0.848  0.946  0.26  -1.23      -0.419
       6             6     0.382   0.65    -0.15   0.353  0.399 -0.466     -0.187
       7             7     0.095  -0.429    0.584  0.556  0.2    0.239     -0.74 
       8             8     0.803   0.588   -0.297  1.31   0.307 -0.423     -0.647
       9             9     0.249   1.62    -0.262  0.656 -0.136 -0.5       -0.608
      10            10     0.23   -0.212   -1.30   0.549 -0.666 -0.428     -0.473
      # i 190 more rows
      # i 14 more variables: `20 hours` <dbl>, `30 hours` <dbl>, `128 GB` <dbl>,
      #   `256 GB` <dbl>, `512 GB` <dbl>, Black <dbl>, Silver <dbl>, Blue <dbl>,
      #   NONE <dbl>, age <int>, gender <chr>, region <chr>, income <dbl>,
      #   education <int+lbl>

# conjoint_df validates the absence column

    Code
      conjoint_df(sample_data(), cw)
    Condition
      Error in `conjoint_df()`:
      x absence in `crosswalk` must be logical.
      i Use TRUE for the absence level of a collection and FALSE otherwise.

---

    Code
      conjoint_df(sample_data(), cw2)
    Condition
      Error in `conjoint_df()`:
      x Collection Storage has more than one absence level.
      ! At most one level per collection may be flagged as absence.

