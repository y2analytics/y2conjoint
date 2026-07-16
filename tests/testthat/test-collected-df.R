test_that("collected_df builds from a data frame and collections", {
  df <- tibble::tibble(share_A = 0.4, share_B = 0.6, id = 1)
  out <- collected_df(df, list(collection("Launch", c("share_A", "share_B"))))

  expect_s3_class(out, "collected_df")
  expect_s3_class(out, "tbl_df")
  expect_length(get_collections(out), 1)
})

test_that("collected_df accepts a single collection or a vector of them", {
  df <- tibble::tibble(share_A = 0.4, share_B = 0.6)

  single <- collected_df(df, collection("Launch", c("share_A", "share_B")))
  expect_length(get_collections(single), 1)

  vec <- collected_df(
    df,
    c(collection("A", "share_A"), collection("B", "share_B"))
  )
  expect_length(get_collections(vec), 2)

  # A list still works and is equivalent to the vector form.
  lst <- collected_df(
    df,
    list(collection("A", "share_A"), collection("B", "share_B"))
  )
  expect_equal(get_collections(vec), get_collections(lst))
})

test_that("collected_df rejects collections whose levels are not columns", {
  df <- tibble::tibble(share_A = 0.4)
  expect_error(
    collected_df(df, list(collection("Launch", c("share_A", "share_B")))),
    "share_B"
  )
})

test_that("collected_df rejects a non-collection element", {
  df <- tibble::tibble(share_A = 0.4)
  expect_error(collected_df(df, list("nope")), "collection")
})

test_that("dplyr verbs preserve the collected_df class", {
  df <- tibble::tibble(share_A = 0.4, share_B = 0.6)
  out <- collected_df(df, list(collection("Launch", c("share_A", "share_B"))))
  kept <- dplyr::mutate(out, extra = 1)

  expect_s3_class(kept, "collected_df")
  expect_length(get_collections(kept), 1)
})

test_that("dropping a collection's column drops the collection with a warning", {
  df <- tibble::tibble(share_A = 0.4, share_B = 0.6)
  out <- collected_df(df, list(collection("Launch", c("share_A", "share_B"))))

  expect_warning(
    dropped <- dplyr::select(out, share_A),
    "Launch"
  )
  expect_length(get_collections(dropped), 0)
})
