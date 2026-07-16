test_that("competitive_set holds its products", {
  cjt <- sample_conjoint()
  cs <- competitive_set(
    product(
      cjt,
      c("Northwind", "$199", "20 hours", "256 GB", "Black"),
      name = "A"
    ),
    product(cjt, c("Cascade", "$299", "10 hours", "128 GB", "Blue"), name = "B")
  )
  expect_length(cs@products, 2)
})

test_that("competitive_set rejects non-product elements", {
  expect_snapshot(error = TRUE, competitive_set(1, 2))
})

test_that("competitive_set prints named and unnamed products", {
  cjt <- sample_conjoint()
  cs <- competitive_set(
    product(
      cjt,
      c("Northwind", "$199", "20 hours", "256 GB", "Black"),
      name = "A"
    ),
    product(cjt, c("Cascade", "$299", "10 hours", "128 GB", "Blue"), name = "B"),
    product(cjt, c("Meridian", "$399", "30 hours", "512 GB", "Silver")),
    name = "Launch"
  )
  expect_snapshot(print(cs))
})

test_that("competitive_set rejects products over different collections", {
  brand_only <- list(collection(
    name = "Brand",
    levels = c("Northwind", "Cascade")
  ))
  price_only <- list(collection(name = "Price", levels = c("$249", "$299")))
  expect_snapshot(
    error = TRUE,
    competitive_set(
      product(brand_only, "Northwind"),
      product(price_only, "$249")
    )
  )
})
