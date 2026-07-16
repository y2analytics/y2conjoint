# product warns when a collection has no selected levels

    Code
      p <- product(cjt, "Northwind")
    Condition
      Warning:
      No levels selected for collections Price, Battery, Storage, and Color.

# product errors on an unknown level

    Code
      product(cjt, "Nokia")
    Condition
      Error in `product()`:
      x Unknown level "Nokia".
      ! Every level must belong to a collection of `x`.
      i Available levels: "Northwind", "Cascade", "Meridian", "$199", "$299", "$399", "10 hours", "20 hours", "30 hours", "128 GB", "256 GB", "512 GB", "Black", "Silver", and "Blue".

# product errors on a duplicated level

    Code
      product(cjt, c("Northwind", "Northwind", "$199"))
    Condition
      Error in `product()`:
      x Level "Northwind" is selected more than once.
      ! Each level may appear at most once in `levels`.

# product rejects an absence level combined with another level

    Code
      product(cols, c("No camera", "8 MP", "A"))
    Condition
      Error in `product()`:
      x Absence level "No camera" cannot be combined with other levels within its collection.

