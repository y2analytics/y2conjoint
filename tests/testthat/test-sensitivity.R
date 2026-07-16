test_that("sensitivity_analysis returns the documented columns", {
  cjt <- sample_conjoint()
  pr <- product(
    cjt,
    c("Northwind", "$299", "20 hours", "256 GB", "Black"),
    name = "Flagship"
  )

  res <- sensitivity_analysis(cjt, multiple_select = "Brand", product = pr)

  expect_named(
    res,
    c(
      "Feature",
      "Level",
      "comparison",
      "preference_share",
      "baseline",
      "delta",
      "product_name"
    )
  )
  expect_setequal(res$comparison, c("added_in", "alone"))
  expect_true(all(res$product_name == "Flagship"))
  expect_equal(res$delta, res$preference_share - res$baseline)
  expect_length(unique(res$baseline), 1L)
})

test_that("single-select collections replace the current level with each other level", {
  cjt <- sample_conjoint()
  pr <- product(cjt, c("Northwind", "$299", "20 hours", "256 GB", "Black"))

  res <- sensitivity_analysis(cjt, multiple_select = character(), product = pr)
  price <- dplyr::filter(res, Feature == "Price")

  expect_setequal(price$comparison, "alone")
  # Every price level except the currently selected one.
  expect_setequal(price$Level, setdiff(c("$199", "$299", "$399"), "$299"))
})

test_that("multiple-select collections add and remove one level at a time", {
  cjt <- sample_conjoint()
  co <- product(
    cjt,
    c("Northwind", "Cascade", "$299", "20 hours", "256 GB", "Black")
  )

  res <- sensitivity_analysis(cjt, multiple_select = "Brand", product = co)
  brand <- dplyr::filter(res, Feature == "Brand")

  # Meridian can be added; the two selected brands can each be taken out.
  expect_setequal(
    brand$comparison[brand$Level == "Meridian"],
    "added_in"
  )
  expect_setequal(
    brand$Level[brand$comparison == "taken_out"],
    c("Northwind", "Cascade")
  )
})

test_that("taken_out is skipped when only one level is selected", {
  cjt <- sample_conjoint()
  pr <- product(cjt, c("Northwind", "$299", "20 hours", "256 GB", "Black"))

  res <- sensitivity_analysis(cjt, multiple_select = "Brand", product = pr)

  expect_false("taken_out" %in% res$comparison)
})

test_that("unknown multiple_select names error", {
  cjt <- sample_conjoint()
  pr <- product(cjt, c("Northwind", "$299", "20 hours", "256 GB", "Black"))

  expect_snapshot(
    error = TRUE,
    sensitivity_analysis(cjt, multiple_select = "Brnd", product = pr)
  )
})

test_that("absence levels are recorded as alone swaps, never paired", {
  cols <- list(
    collection(
      "Camera",
      c("No camera", "8 MP", "12 MP"),
      absence = "No camera"
    ),
    collection("Brand", c("A", "B"))
  )
  data <- tibble::tibble(
    `No camera` = c(0, 0),
    `8 MP` = c(1, 1),
    `12 MP` = c(2, 2),
    A = c(1, 1),
    B = c(0, 0),
    NONE = c(0, 0)
  )
  cjt <- new_conjoint_df(data, collections = cols, none = "NONE")

  # Camera currently holds a feature (8 MP); adding "No camera" would pair the
  # absence level with a feature, so it must become an alone swap instead.
  pr <- product(cols, c("8 MP", "A"))
  res <- sensitivity_analysis(cjt, multiple_select = "Camera", product = pr)
  camera <- dplyr::filter(res, Feature == "Camera")

  expect_equal(
    camera$comparison[camera$Level == "No camera"],
    "alone"
  )
  # A genuine feature addition is still an added_in.
  expect_equal(
    camera$comparison[camera$Level == "12 MP"],
    "added_in"
  )
})
