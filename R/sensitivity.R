#' Sensitivity analysis for a product specification
#'
#' Measures how a product's preference share responds to changing one level at a
#' time. The unchanged [product] is scored on its own (against the NONE outside
#' good) to give a `baseline` share, then each collection is perturbed
#' individually - never in combination with another collection - and re-scored:
#'
#' * **Single-select** collections (the default) are perturbed by replacing the
#'   current level with each other level in turn (`comparison = "alone"`).
#' * **Multiple-select** collections (those named in `multiple_select`) are
#'   perturbed by adding each not-yet-selected level (`comparison = "added_in"`)
#'   and, when two or more levels are already selected, by removing each selected
#'   level (`comparison = "taken_out"`).
#'
#' An absence level (see [collection]) can never be paired with another level, so
#' for a multiple-select collection any addition that would pair with the absence
#' level is instead recorded as an `"alone"` swap (the candidate level on its
#' own) rather than an `"added_in"`.
#'
#' @param x A [conjoint_df] of individual-level utilities.
#' @param multiple_select A character vector of collection names that may hold
#'   more than one level at once. Collections not listed here are treated as
#'   single-select.
#' @param product The [product] to analyse.
#' @param combine_fn How to combine multiple selected levels within a collection.
#'   Passed through to [run_scenario()]. Either a single function applied to
#'   every collection (the default, [pmax()]), or a named list mapping collection
#'   names to functions.
#' @param scaling_factor A numeric multiplier applied to all utilities before the
#'   softmax. Passed through to [run_scenario()]. Defaults to `1`.
#'
#' @return A tibble with one row per perturbation and the columns:
#'   `Feature` (collection name), `Level` (the level added, removed, or
#'   substituted), `comparison` (`"added_in"`, `"taken_out"`, or `"alone"`),
#'   `preference_share` (share of the perturbed product), `baseline` (share of
#'   the unchanged product), `delta` (`preference_share - baseline`), and
#'   `product_name`.
#' @examples
#' cjt <- conjoint_df(example_utilities, example_crosswalk)
#' flagship <- product(
#'   cjt,
#'   c("Northwind", "$299", "20 hours", "256 GB", "Black"),
#'   name = "Flagship"
#' )
#' sensitivity_analysis(cjt, multiple_select = "Brand", product = flagship)
#' @export
sensitivity_analysis <- function(
  x,
  multiple_select,
  product,
  combine_fn = pmax,
  scaling_factor = 1
) {
  collections <- get_collections(x)
  collection_names <- purrr::map_chr(collections, \(cl) cl@name)
  check_multiple_select(multiple_select, collection_names)

  product_name <- product_display_name(product)
  # run_scenario() now returns one row per competitive set with a leading
  # `competitive_set` column, so the product's own share must be pulled out by
  # its column name (the same name S7::set_props() below preserves across
  # perturbations) rather than by position.
  product_col <- paste0("share_", product_output_names(list(product)))

  # The unchanged product scored on its own is the reference every delta is
  # measured against.
  baseline <- run_scenario(
    x,
    competitive_set(product),
    combine_fn = combine_fn,
    scaling_factor = scaling_factor
  )[[product_col]]

  # Build one row per single-level perturbation, carrying the modified selection
  # vector so we can re-score it below.
  grid <- perturbation_grid(product, collections, multiple_select)

  # A product with no valid perturbations (e.g. a single-level, single-select
  # attribute) still returns the correct empty-shaped tibble.
  if (nrow(grid) == 0) {
    return(sensitivity_tibble(grid, baseline, product_name))
  }

  grid$preference_share <- purrr::map2_dbl(
    grid$Feature,
    grid$new_levels,
    function(feature, new_levels) {
      run_scenario(
        x,
        competitive_set(set_selection(product, feature, new_levels)),
        combine_fn = combine_fn,
        scaling_factor = scaling_factor
      )[[product_col]]
    }
  )

  sensitivity_tibble(grid, baseline, product_name)
}

# Assemble the final output columns in a fixed order.
#' @keywords internal
sensitivity_tibble <- function(grid, baseline, product_name) {
  if (nrow(grid) == 0) {
    return(tibble::tibble(
      Feature = character(),
      Level = character(),
      comparison = character(),
      preference_share = numeric(),
      baseline = numeric(),
      delta = numeric(),
      product_name = character()
    ))
  }
  grid |>
    dplyr::mutate(
      .keep = "none",
      .data$Feature,
      .data$Level,
      .data$comparison,
      .data$preference_share,
      baseline = .env$baseline,
      delta = .data$preference_share - .env$baseline,
      product_name = .env$product_name
    )
}
