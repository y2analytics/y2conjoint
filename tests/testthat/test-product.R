test_that("product groups levels by collection", {
  cjt <- sample_conjoint()
  p <- product(
    cjt,
    c("Northwind", "$199", "20 hours", "256 GB", "Black"),
    name = "Cheap"
  )
  expect_equal(p@name, "Cheap")
  expect_equal(p@selections$Brand, "Northwind")
  expect_equal(p@selections$Price, "$199")
})

test_that("product allows multiple levels within one collection", {
  cjt <- sample_conjoint()
  p <- product(
    cjt,
    c("Northwind", "Cascade", "$199", "20 hours", "256 GB", "Black")
  )
  expect_setequal(p@selections$Brand, c("Northwind", "Cascade"))
})

test_that("product warns when a collection has no selected levels", {
  cjt <- sample_conjoint()
  expect_snapshot(p <- product(cjt, "Northwind"))
  expect_equal(p@selections$Price, character())
})

test_that("product errors on an unknown level", {
  cjt <- sample_conjoint()
  expect_snapshot(error = TRUE, product(cjt, "Nokia"))
})

test_that("product errors on a duplicated level", {
  cjt <- sample_conjoint()
  expect_snapshot(error = TRUE, product(cjt, c("Northwind", "Northwind", "$199")))
})

test_that("product allows an absence level selected on its own", {
  cols <- list(
    collection(
      "Camera",
      c("No camera", "8 MP", "12 MP"),
      absence = "No camera"
    ),
    collection("Brand", c("A", "B"))
  )
  p <- product(cols, c("No camera", "A"))
  expect_equal(p@selections$Camera, "No camera")
})

test_that("product rejects an absence level combined with another level", {
  cols <- list(
    collection(
      "Camera",
      c("No camera", "8 MP", "12 MP"),
      absence = "No camera"
    ),
    collection("Brand", c("A", "B"))
  )
  expect_snapshot(
    error = TRUE,
    product(cols, c("No camera", "8 MP", "A"))
  )
})
