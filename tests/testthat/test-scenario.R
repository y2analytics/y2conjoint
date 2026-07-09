test_that("compute_product_utility combines within and sums across collections", {
  cjt <- sample_conjoint()
  s <- spec(
    cjt,
    c("Northwind", "Cascade", "$199", "20 hours", "256 GB", "Black")
  )
  expected <- pmax(cjt$Northwind, cjt[["Cascade"]]) +
    cjt[["$199"]] +
    cjt[["20 hours"]] +
    cjt[["256 GB"]] +
    cjt[["Black"]]
  expect_equal(compute_product_utility(cjt, s), expected)
})

test_that("compute_product_utility accepts a per-collection combine_fn", {
  cjt <- sample_conjoint()
  s <- spec(
    cjt,
    c("Northwind", "Cascade", "$199", "20 hours", "256 GB", "Black")
  )
  # Sum brand levels, leave the rest to the pmax fallback.
  expected <- (cjt$Northwind + cjt[["Cascade"]]) +
    cjt[["$199"]] +
    cjt[["20 hours"]] +
    cjt[["256 GB"]] +
    cjt[["Black"]]
  actual <- compute_product_utility(cjt, s, combine_fn = list(Brand = `+`))
  expect_equal(actual, expected)
})

test_that("run_scenario rejects combine_fn naming an unknown collection", {
  cjt <- sample_conjoint()
  cs <- competitive_set(
    spec(cjt, c("Northwind", "$199", "20 hours", "256 GB", "Black"), name = "A")
  )
  expect_snapshot(
    error = TRUE,
    run_scenario(cjt, cs, combine_fn = list(Colour = pmax))
  )
})

test_that("run_scenario returns one named share column per product", {
  cjt <- sample_conjoint()
  cs <- competitive_set(
    spec(
      cjt,
      c("Northwind", "$199", "20 hours", "256 GB", "Black"),
      name = "A"
    ),
    spec(cjt, c("Cascade", "$299", "10 hours", "128 GB", "Blue"), name = "B")
  )
  out <- run_scenario(cjt, cs)
  expect_named(out, c("share_A", "share_B"))
})

test_that("run_scenario names unnamed specs sequentially", {
  cjt <- sample_conjoint()
  cs <- competitive_set(
    spec(cjt, c("Northwind", "$199", "20 hours", "256 GB", "Black")),
    spec(cjt, c("Cascade", "$299", "10 hours", "128 GB", "Blue"))
  )
  out <- run_scenario(cjt, cs)
  expect_named(out, c("share_product_1", "share_product_2"))
})

test_that("run_scenario matches a hand-computed softmax", {
  cjt <- sample_conjoint()
  cs <- competitive_set(
    spec(cjt, c("Northwind", "$199", "20 hours", "256 GB", "Black"), name = "A")
  )
  util_a <- cjt$Northwind +
    cjt[["$199"]] +
    cjt[["20 hours"]] +
    cjt[["256 GB"]] +
    cjt[["Black"]]
  util_none <- cjt$NONE
  row_max <- pmax(util_a, util_none)
  exp_a <- exp(util_a - row_max)
  exp_none <- exp(util_none - row_max)
  share_a <- round(mean(exp_a / (exp_a + exp_none)), 3)
  expect_equal(run_scenario(cjt, cs)$share_A, share_a)
})

test_that("run_scenario .by adds group_var, group_level, and n columns", {
  cjt <- sample_conjoint()
  cs <- competitive_set(
    spec(cjt, c("Northwind", "$199", "20 hours", "256 GB", "Black"), name = "A")
  )
  out <- run_scenario(cjt, cs, .by = region)

  expect_named(out, c("group_var", "group_level", "n", "share_A"))
  expect_true(all(out$group_var == "region"))
  expect_setequal(out$group_level, as.character(unique(cjt$region)))
  # Subgroup sizes partition the sample.
  expect_equal(sum(out$n), nrow(cjt))
})

test_that("run_scenario .by stacks several grouping variables marginally", {
  cjt <- sample_conjoint()
  cs <- competitive_set(
    spec(cjt, c("Northwind", "$199", "20 hours", "256 GB", "Black"), name = "A")
  )
  out <- run_scenario(cjt, cs, .by = c(region, gender))

  expect_setequal(unique(out$group_var), c("region", "gender"))
  # Each variable's subgroups independently partition the sample.
  totals <- dplyr::summarise(out, total = sum(n), .by = group_var)
  expect_true(all(totals$total == nrow(cjt)))
})

test_that("run_scenario subgroup shares match a manual subset", {
  cjt <- sample_conjoint()
  cs <- competitive_set(
    spec(cjt, c("Northwind", "$199", "20 hours", "256 GB", "Black"), name = "A")
  )
  out <- run_scenario(cjt, cs, .by = region)

  first <- sort(unique(cjt$region))[1]
  manual <- run_scenario(dplyr::filter(cjt, region == first), cs)
  expect_equal(
    out$share_A[out$group_level == first],
    manual$share_A
  )
})

test_that("run_scenario .by places missing values in their own subgroup", {
  cjt <- sample_conjoint()
  cjt <- dplyr::mutate(
    cjt,
    seg = rep(c("A", "B", NA), length.out = dplyr::n())
  )
  cs <- competitive_set(
    spec(cjt, c("Northwind", "$199", "20 hours", "256 GB", "Black"), name = "A")
  )
  out <- run_scenario(cjt, cs, .by = seg)

  expect_true(anyNA(out$group_level))
  na_row <- out[is.na(out$group_level), ]
  expect_equal(na_row$n, sum(is.na(cjt$seg)))
  # A missing value does not silently vanish: subgroup sizes still add up.
  expect_equal(sum(out$n), nrow(cjt))
})

test_that("run_scenario .by uses value labels for haven_labelled columns", {
  cjt <- sample_conjoint()
  cs <- competitive_set(
    spec(cjt, c("Northwind", "$199", "20 hours", "256 GB", "Black"), name = "A")
  )
  out <- run_scenario(cjt, cs, .by = education)

  labels <- names(attr(cjt$education, "labels"))
  # Rows are labelled in human terms, in the label (code) order, not bare codes.
  expect_equal(out$group_level, labels)
  expect_equal(sum(out$n), nrow(cjt))
})
