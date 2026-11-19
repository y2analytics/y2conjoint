tiny_conjoint <- function(
  f2 = 0.5,
  price_levels = c("$10", "$20"),
  price_utils = matrix(c(1, 0), nrow = 3, ncol = 2, byrow = TRUE)
) {
  cols <- list(
    ordered_collection("Price", price_levels),
    collection("Feat", c("F1", "F2"))
  )
  colnames(price_utils) <- price_levels
  data <- tibble::as_tibble(price_utils)
  data$F1 <- 0
  data$F2 <- f2
  data$NONE <- 0
  new_conjoint_df(data, collections = cols, none = "NONE")
}

tiny_reference <- function(cjt) {
  product(cjt, c("$10", "F1"), name = "A")
}

test_that("willingness_to_pay returns the documented columns, one row per change", {
  cjt <- sample_conjoint()
  pr <- product(
    cjt,
    c("Northwind", "$299", "20 hours", "256 GB", "Black"),
    name = "Flagship"
  )

  res <- suppressMessages(willingness_to_pay(cjt, pr))

  expect_named(
    res,
    c(
      "alternative",
      "reference_price",
      "matched_price",
      "willingness_to_pay",
      "reference_share",
      "alternative_share",
      "extrapolated",
      "product_name"
    )
  )
  sens <- sensitivity_analysis(cjt, multiple_select = character(), product = pr)
  expect_equal(nrow(res), sum(sens$Feature != "Price"))
  expect_equal(
    res$willingness_to_pay,
    res$matched_price - res$reference_price
  )
  expect_true(all(res$product_name == "Flagship"))
  expect_equal(res$reference_price, rep(299, nrow(res)))
  expect_false(any(grepl("^Price", res$alternative)))
  unpooled <- willingness_to_pay(cjt, pr, monotone_price = FALSE)
  expect_equal(
    unique(unpooled$reference_share),
    run_scenario(cjt, competitive_set(pr))$share_Flagship
  )
})

test_that("extrapolate solves for the price where shares are equal", {
  cjt <- tiny_conjoint(f2 = 0.5)
  res <- willingness_to_pay(
    cjt,
    tiny_reference(cjt),
    alternatives = "F2"
  )

  expect_equal(res$matched_price, 15)
  expect_equal(res$willingness_to_pay, 5)
  expect_equal(res$alternative_share, res$reference_share)
  expect_false(res$extrapolated)
})

test_that("a worse alternative needs a discount", {
  cjt <- tiny_conjoint(f2 = -0.5)
  res <- suppressMessages(
    willingness_to_pay(cjt, tiny_reference(cjt), alternatives = "F2")
  )

  expect_equal(res$matched_price, 5)
  expect_equal(res$willingness_to_pay, -5)
  expect_true(res$extrapolated)
})

test_that("extrapolation beyond the conjoint's price range is flagged and reported", {
  cjt <- tiny_conjoint(f2 = 2)

  expect_snapshot(
    res <- willingness_to_pay(cjt, tiny_reference(cjt), alternatives = "F2")
  )
  expect_equal(res$matched_price, 30)
  expect_true(res$extrapolated)
})

test_that("an unchanged alternative has zero willingness to pay", {
  cjt <- sample_conjoint()
  pr <- product(cjt, c("Northwind", "$299", "20 hours", "256 GB", "Black"))

  res <- willingness_to_pay(cjt, pr, alternatives = "20 hours")

  expect_equal(res$willingness_to_pay, 0)
  expect_equal(res$alternative, "(no change)")
})

test_that("a price that cannot be matched returns NA with a warning", {
  cjt <- tiny_conjoint(f2 = -5)

  expect_snapshot(
    res <- willingness_to_pay(cjt, tiny_reference(cjt), alternatives = "F2")
  )
  expect_true(is.na(res$matched_price))
  expect_true(is.na(res$willingness_to_pay))
  expect_gt(res$reference_share, 0)
})

test_that("closest picks the nearest tested price level", {
  cjt <- tiny_conjoint(f2 = 0.8)
  res <- willingness_to_pay(
    cjt,
    tiny_reference(cjt),
    alternatives = "F2",
    match = "closest"
  )

  expect_equal(res$matched_price, 20)
  expect_equal(res$willingness_to_pay, 10)
  expect_false(res$extrapolated)
})

test_that("closest_without_going_over keeps the alternative at or above the reference share", {
  cjt <- tiny_conjoint(f2 = 0.8)
  res <- willingness_to_pay(
    cjt,
    tiny_reference(cjt),
    alternatives = "F2",
    match = "closest_without_going_over"
  )

  expect_equal(res$matched_price, 10)
  expect_gte(res$alternative_share, res$reference_share)
})

test_that("discrete matches at the edge of the price range point to extrapolate", {
  cjt <- tiny_conjoint(f2 = 2)

  expect_snapshot(
    res <- willingness_to_pay(
      cjt,
      tiny_reference(cjt),
      alternatives = "F2",
      match = "closest"
    )
  )
  expect_equal(res$matched_price, 20)
})

test_that("alternatives accepts levels, products, and named lists", {
  cjt <- sample_conjoint()
  pr <- product(
    cjt,
    c("Northwind", "$299", "20 hours", "256 GB", "Black"),
    name = "Flagship"
  )
  better <- product(
    cjt,
    c("Northwind", "$299", "30 hours", "512 GB", "Black"),
    name = "Better"
  )

  res <- suppressMessages(willingness_to_pay(
    cjt,
    pr,
    alternatives = list(
      Levels = c("30 hours", "512 GB"),
      better,
      "Silver"
    )
  ))

  expect_equal(
    res$alternative,
    c("Levels", "Better", "Color: Black \u2192 Silver")
  )
  expect_equal(res$matched_price[[1]], res$matched_price[[2]])
})

test_that("new levels replace every level of the collections they touch", {
  cjt <- sample_conjoint()
  pr <- product(cjt, c("Northwind", "$299", "20 hours", "256 GB", "Black"))

  res <- suppressMessages(willingness_to_pay(
    cjt,
    pr,
    alternatives = c("Northwind", "Cascade")
  ))

  expect_equal(res$alternative, "Brand: Northwind \u2192 Northwind + Cascade")
})

test_that("multiple_select adds brands in the default one-at-a-time mode", {
  cjt <- sample_conjoint()
  pr <- product(cjt, c("Northwind", "$299", "20 hours", "256 GB", "Black"))

  res <- suppressMessages(willingness_to_pay(
    cjt,
    pr,
    multiple_select = "Brand"
  ))

  expect_true(
    "Brand: Northwind \u2192 Northwind + Cascade" %in% res$alternative
  )
})

test_that("a different price on an alternative is ignored with a warning", {
  cjt <- sample_conjoint()
  pr <- product(cjt, c("Northwind", "$299", "20 hours", "256 GB", "Black"))
  pricey <- product(
    cjt,
    c("Northwind", "$399", "30 hours", "256 GB", "Black"),
    name = "Pricey"
  )
  cheap_levels <- c("30 hours", "$199")

  expect_snapshot(
    res <- willingness_to_pay(
      cjt,
      pr,
      alternatives = list(pricey, cheap_levels),
      monotone_price = FALSE
    )
  )
  expect_equal(res$matched_price[[1]], res$matched_price[[2]])
})

test_that("price_values supplies numbers for levels that do not contain any", {
  cjt <- tiny_conjoint(f2 = 0.5, price_levels = c("Low", "High"))
  pr <- product(cjt, c("Low", "F1"))

  expect_snapshot(
    error = TRUE,
    willingness_to_pay(cjt, pr, alternatives = "F2")
  )
  res <- willingness_to_pay(
    cjt,
    pr,
    alternatives = "F2",
    price_values = c(Low = 10, High = 20)
  )
  expect_equal(res$matched_price, 15)
})

test_that("price levels with thousands separators and currency are parsed", {
  expect_equal(
    resolve_price_values(c("$1,299", "$999.50"), NULL),
    c("$999.50" = 999.5, "$1,299" = 1299)
  )
})

test_that("scaling_factor is applied to the reference and the alternatives", {
  cjt <- sample_conjoint()
  pr <- product(
    cjt,
    c("Northwind", "$299", "20 hours", "256 GB", "Black"),
    name = "Flagship"
  )

  res <- willingness_to_pay(
    cjt,
    pr,
    scaling_factor = 2,
    monotone_price = FALSE
  )

  expect_equal(
    unique(res$reference_share),
    run_scenario(cjt, competitive_set(pr), scaling_factor = 2)$share_Flagship
  )
})

test_that("invalid inputs error clearly", {
  cjt <- sample_conjoint()
  pr <- product(cjt, c("Northwind", "$299", "20 hours", "256 GB", "Black"))
  no_price <- suppressWarnings(product(cjt, c("Northwind", "20 hours")))

  expect_snapshot(error = TRUE, {
    willingness_to_pay(cjt, pr, price = "Cost")
    willingness_to_pay(cjt, no_price)
    willingness_to_pay(cjt, pr, alternatives = 1)
    willingness_to_pay(cjt, pr, alternatives = "Nope")
    willingness_to_pay(cjt, pr, match = "nearest")
    willingness_to_pay(cjt, pr, price_values = c("$199" = 199))
    willingness_to_pay(cjt, pr, individual = "yes")
    willingness_to_pay(cjt, pr, monotone_price = NA)
    willingness_to_pay(cjt, pr, individual = TRUE, id = "nope")
  })
})

test_that("pool_decreasing makes utilities non-increasing by averaging violators", {
  expect_equal(pool_decreasing(c(3, 2, 1)), c(3, 2, 1))
  expect_equal(pool_decreasing(c(1, 0.2, 0.6)), c(1, 0.4, 0.4))
  expect_equal(pool_decreasing(c(0, 1, 2)), c(1, 1, 1))
  expect_equal(pool_decreasing(c(1, 0, 0.5, 0.9)), c(1, rep(1.4 / 3, 3)))
})

test_that("price reversals are pooled, flagged, and reported", {
  cjt <- sample_conjoint()
  pr <- product(cjt, c("Northwind", "$299", "20 hours", "256 GB", "Black"))

  expect_snapshot(
    res <- willingness_to_pay(
      cjt,
      pr,
      alternatives = "30 hours",
      individual = TRUE
    )
  )
  prices <- matrix(c(cjt[["$199"]], cjt[["$299"]], cjt[["$399"]]), ncol = 3)
  expect_equal(res$price_reversal, price_reversals(prices))
})

test_that("monotone_price changes the match for a respondent with a reversal", {
  cjt <- tiny_conjoint(
    price_levels = c("$10", "$20", "$30"),
    price_utils = matrix(c(1, 0, 0.5), nrow = 1)
  )
  pr <- product(cjt, c("$10", "F1"))

  pooled <- suppressMessages(
    willingness_to_pay(cjt, pr, alternatives = "F2", individual = TRUE)
  )
  raw <- willingness_to_pay(
    cjt,
    pr,
    alternatives = "F2",
    individual = TRUE,
    monotone_price = FALSE
  )

  expect_equal(pooled$matched_price, 16.67)
  expect_equal(raw$matched_price, 15)
  expect_true(pooled$price_reversal)
  expect_equal(
    suppressMessages(willingness_to_pay(
      cjt,
      pr,
      alternatives = "F2"
    ))$matched_price,
    pooled$matched_price
  )
})

test_that("a product matches itself on a pooled flat stretch", {
  cjt <- tiny_conjoint(
    price_levels = c("$10", "$20", "$30"),
    price_utils = matrix(c(1, 0.2, 0.6), nrow = 1)
  )
  pr <- product(cjt, c("$30", "F1"))

  res <- suppressMessages(
    willingness_to_pay(cjt, pr, alternatives = "F1", individual = TRUE)
  )

  expect_equal(res$willingness_to_pay, 0)
})

test_that("individual willingness to pay is solved per respondent", {
  cjt <- tiny_conjoint(
    f2 = 0.5,
    price_utils = matrix(c(1, 0, 2, 0), nrow = 2, byrow = TRUE)
  )

  res <- willingness_to_pay(
    cjt,
    tiny_reference(cjt),
    alternatives = "F2",
    individual = TRUE
  )

  expect_named(
    res,
    c(
      "respondent",
      "alternative",
      "reference_price",
      "matched_price",
      "willingness_to_pay",
      "extrapolated",
      "price_reversal",
      "product_name"
    )
  )
  expect_equal(res$respondent, 1:2)
  expect_equal(res$matched_price, c(15, 12.5))
  expect_equal(res$willingness_to_pay, c(5, 2.5))
})

test_that("individual results match the aggregate when respondents are identical", {
  cjt <- tiny_conjoint(f2 = 0.5)
  pr <- tiny_reference(cjt)

  ind <- willingness_to_pay(cjt, pr, alternatives = "F2", individual = TRUE)
  agg <- willingness_to_pay(cjt, pr, alternatives = "F2")

  expect_equal(ind$matched_price, rep(agg$matched_price, 3))
})

test_that("individual results use id and have one row per respondent and alternative", {
  cjt <- sample_conjoint()
  pr <- product(cjt, c("Northwind", "$299", "20 hours", "256 GB", "Black"))

  res <- suppressMessages(suppressWarnings(willingness_to_pay(
    cjt,
    pr,
    alternatives = list(a = "30 hours", b = "512 GB"),
    individual = TRUE,
    id = "respondent_id"
  )))

  expect_equal(nrow(res), 400L)
  expect_equal(names(res)[[1]], "respondent_id")
  expect_equal(res$respondent_id, rep(cjt$respondent_id, 2))
  expect_equal(res$alternative, rep(c("a", "b"), each = 200))
})

test_that("individual matches that do not exist are NA with a warning", {
  cjt <- tiny_conjoint(f2 = 1, price_utils = matrix(0, nrow = 1, ncol = 2))

  expect_snapshot(
    res <- willingness_to_pay(
      cjt,
      tiny_reference(cjt),
      alternatives = "F2",
      individual = TRUE
    )
  )
  expect_true(is.na(res$willingness_to_pay))
})
