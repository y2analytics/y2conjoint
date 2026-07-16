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

  product_name <- if (length(product@name) == 1 && nzchar(product@name)) {
    product@name
  } else {
    "(unnamed)"
  }
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
  grid <- purrr::map(collections, function(cl) {
    perturb_collection(
      cl,
      current = product@selections[[cl@name]],
      multiple_select = multiple_select
    )
  })
  grid <- dplyr::bind_rows(grid)

  # A product with no valid perturbations (e.g. a single-level, single-select
  # attribute) still returns the correct empty-shaped tibble.
  if (nrow(grid) == 0) {
    return(sensitivity_tibble(grid, baseline, product_name))
  }

  grid$preference_share <- purrr::map2_dbl(
    grid$Feature,
    grid$new_levels,
    function(feature, new_levels) {
      selections <- product@selections
      selections[[feature]] <- new_levels
      run_scenario(
        x,
        competitive_set(S7::set_props(product, selections = selections)),
        combine_fn = combine_fn,
        scaling_factor = scaling_factor
      )[[product_col]]
    }
  )

  sensitivity_tibble(grid, baseline, product_name)
}

# Enumerate the single-level perturbations for one collection, returning a tibble
# of candidate rows with the modified selection vector stored in `new_levels`.
#' @keywords internal
#' @importFrom rlang .data .env
perturb_collection <- function(cl, current, multiple_select) {
  name <- cl@name
  levels <- collection_levels(cl)
  absence <- collection_absence(cl)

  if (name %in% multiple_select) {
    add <- setdiff(levels, current)
    # Adding a level normally keeps the existing selection. But an absence level
    # can never be paired with another level, so any addition that would pair
    # with the absence level is recorded as an "alone" swap (the candidate on its
    # own) instead of an "added_in".
    added <- if (length(add) > 0) {
      dplyr::bind_rows(purrr::map(add, function(lv) {
        candidate <- c(current, lv)
        pairs_absence <- length(absence) == 1 &&
          absence %in% candidate &&
          length(candidate) > 1
        tibble::tibble(
          Feature = name,
          Level = lv,
          comparison = if (pairs_absence) "alone" else "added_in",
          new_levels = if (pairs_absence) list(lv) else list(candidate)
        )
      }))
    } else {
      NULL
    }
    # Removing a level only makes sense when more than one remains; a
    # single-level collection would otherwise be emptied entirely.
    taken <- if (length(current) >= 2) {
      tibble::tibble(
        Feature = name,
        Level = current,
        comparison = "taken_out",
        new_levels = purrr::map(current, \(lv) setdiff(current, lv))
      )
    } else {
      NULL
    }
    dplyr::bind_rows(added, taken)
  } else {
    other <- setdiff(levels, current)
    tibble::tibble(
      Feature = name,
      Level = other,
      comparison = "alone",
      new_levels = purrr::map(other, \(lv) lv)
    )
  }
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

# Fail early if a name in `multiple_select` is not a real collection of `x`.
#' @keywords internal
check_multiple_select <- function(
  multiple_select,
  collection_names,
  call = rlang::caller_env()
) {
  if (!is.character(multiple_select)) {
    cli::cli_abort(
      c(
        "x" = "{.arg multiple_select} must be a character vector of collection names.",
        "i" = "You supplied {.obj_type_friendly {multiple_select}}."
      ),
      call = call
    )
  }
  unknown <- setdiff(multiple_select, collection_names)
  if (length(unknown) > 0) {
    cli::cli_abort(
      c(
        "x" = "{.arg multiple_select} names {cli::qty(unknown)}collection{?s} not found in {.arg x}.",
        "!" = "Unknown: {.field {unknown}}.",
        "i" = "Available collections: {.field {collection_names}}."
      ),
      call = call
    )
  }
  invisible()
}
