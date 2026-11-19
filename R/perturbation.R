# Every single-level perturbation of `product`, one row per candidate, across
# all `collections` except those named in `exclude`. The modified selection
# vector is stored in the `new_levels` list column.
#' @keywords internal
perturbation_grid <- function(
  product,
  collections,
  multiple_select,
  exclude = character()
) {
  collections <- purrr::discard(collections, \(cl) cl@name %in% exclude)
  grid <- purrr::map(collections, function(cl) {
    perturb_collection(
      cl,
      current = product@selections[[cl@name]],
      multiple_select = multiple_select
    )
  })
  dplyr::bind_rows(grid)
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
