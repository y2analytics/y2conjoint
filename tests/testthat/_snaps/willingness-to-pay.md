# extrapolation beyond the conjoint's price range is flagged and reported

    Code
      res <- willingness_to_pay(cjt, tiny_reference(cjt), alternatives = "F2")
    Message
      i Extrapolated beyond the price range of the conjoint (10 to 20) for "Feat: F1 → F2".

# a price that cannot be matched returns NA with a warning

    Code
      res <- willingness_to_pay(cjt, tiny_reference(cjt), alternatives = "F2")
    Condition
      Warning in `willingness_to_pay()`:
      ! No matching price for alternative "Feat: F1 → F2".
      i The shares never meet at a price of 0 or more.

# discrete matches at the edge of the price range point to extrapolate

    Code
      res <- willingness_to_pay(cjt, tiny_reference(cjt), alternatives = "F2", match = "closest")
    Message
      i "Feat: F1 → F2" still differs from the reference at the edge of the conjoint's price range, so the true match lies beyond it.
      i Use `match = "extrapolate"` to estimate it.

# a different price on an alternative is ignored with a warning

    Code
      res <- willingness_to_pay(cjt, pr, alternatives = list(pricey, cheap_levels),
      monotone_price = FALSE)
    Condition
      Warning in `willingness_to_pay()`:
      ! Ignoring the Price of "Pricey" and "Battery: 20 hours → 30 hours".
      i Price is solved for, so it is not taken from the alternative.

# price_values supplies numbers for levels that do not contain any

    Code
      willingness_to_pay(cjt, pr, alternatives = "F2")
    Condition
      Error in `willingness_to_pay()`:
      x Can't read a price from levels "Low" and "High".
      i Each price level must contain exactly one number, or supply `price_values`.

# invalid inputs error clearly

    Code
      willingness_to_pay(cjt, pr, price = "Cost")
    Condition
      Error in `willingness_to_pay()`:
      x `price` must name a single collection of `x`.
      i Available collections: Brand, Price, Battery, Storage, and Color.
    Code
      willingness_to_pay(cjt, no_price)
    Condition
      Error in `willingness_to_pay()`:
      x `product` must select exactly one level of Price.
      i It selects 0.
    Code
      willingness_to_pay(cjt, pr, alternatives = 1)
    Condition
      Error in `willingness_to_pay()`:
      x `alternatives` must be `NULL`, a <product>, a character vector of levels, or a list of those.
      i You supplied a number.
    Code
      willingness_to_pay(cjt, pr, alternatives = "Nope")
    Condition
      Error in `willingness_to_pay()`:
      x Unknown level "Nope".
      ! Every level must belong to a collection of `x`.
      i Available levels: "Northwind", "Cascade", "Meridian", "$199", "$299", "$399", "10 hours", "20 hours", "30 hours", "128 GB", "256 GB", "512 GB", "Black", "Silver", and "Blue".
    Code
      willingness_to_pay(cjt, pr, match = "nearest")
    Condition
      Error in `willingness_to_pay()`:
      ! `match` must be one of "extrapolate", "closest", or "closest_without_going_over", not "nearest".
    Code
      willingness_to_pay(cjt, pr, price_values = c(`$199` = 199))
    Condition
      Error in `willingness_to_pay()`:
      x `price_values` must have exactly one value per price level.
      ! Missing: "$299" and "$399".
      i Price levels: "$199", "$299", and "$399".
    Code
      willingness_to_pay(cjt, pr, individual = "yes")
    Condition
      Error in `willingness_to_pay()`:
      x `individual` must be `TRUE` or `FALSE`.
      i You supplied a string.
    Code
      willingness_to_pay(cjt, pr, monotone_price = NA)
    Condition
      Error in `willingness_to_pay()`:
      x `monotone_price` must be `TRUE` or `FALSE`.
      i You supplied `NA`.
    Code
      willingness_to_pay(cjt, pr, individual = TRUE, id = "nope")
    Condition
      Error in `willingness_to_pay()`:
      x `id` must name a column of `x`.
      ! Not found: nope.

# price reversals are pooled, flagged, and reported

    Code
      res <- willingness_to_pay(cjt, pr, alternatives = "30 hours", individual = TRUE)
    Message
      i Pooled the price utilities of 64 of 200 respondents whose utility rose with price.
        Set `monotone_price = FALSE` to use them as they are.
    Condition
      Warning in `willingness_to_pay()`:
      ! No matching price for 34 of 200 respondent-alternative pairs.
      i The shares never meet at a price of 0 or more.
    Message
      i 59 of 200 respondent-alternative pairs extrapolated beyond the price range of the conjoint (199 to 399).

# individual matches that do not exist are NA with a warning

    Code
      res <- willingness_to_pay(cjt, tiny_reference(cjt), alternatives = "F2",
      individual = TRUE)
    Condition
      Warning in `willingness_to_pay()`:
      ! No matching price for 1 of 1 respondent-alternative pair.
      i The shares never meet at a price of 0 or more.

