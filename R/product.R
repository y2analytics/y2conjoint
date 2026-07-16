#' Define a product specification
#'
#' A `product` records the levels that make up a single product, grouped by
#' collection. It is built from a flat vector of user-facing level names (any
#' subset is allowed, including selecting several levels from one collection);
#' the levels are validated against, and grouped by, the collections of `x`.
#'
#' @param x A [conjoint_df] or a list of [collection]s to validate against.
#' @param levels A character vector of user-facing level names.
#' @param name An optional single string naming the product.
#'
#' @return A `product` object.
#' @examples
#' cjt <- conjoint_df(example_utilities, example_crosswalk)
#'
#' # Select one level per collection.
#' product(cjt, c("Northwind", "$299", "20 hours", "256 GB", "Black"), name = "Flagship")
#'
#' # Selecting several brands models a co-branded product.
#' product(
#'   cjt,
#'   c("Northwind", "Cascade", "$199", "10 hours", "128 GB", "Blue"),
#'   name = "Co-brand"
#' )
#'
#' # Any subset is allowed; omitted collections warn and contribute no utility.
#' product(cjt, c("Meridian", "$399"), name = "Sparse")
#' @export
product <- S7::new_class(
  "product",
  properties = list(
    name = S7::class_character,
    selections = S7::class_list
  ),
  constructor = function(x, levels, name = character()) {
    S7::new_object(
      S7::S7_object(),
      name = name,
      selections = group_levels(x, levels)
    )
  },
  validator = function(self) {
    validate_product_fields(self@name, self@selections)
  }
)

#' @keywords internal
validate_product_fields <- function(name, selections) {
  if (length(name) > 1) {
    return("@name must be a single string or empty")
  }
  if (is.null(names(selections)) || !all(nzchar(names(selections)))) {
    return("@selections must be a named list")
  }
  is_chr <- purrr::map_lgl(selections, is.character)
  if (!all(is_chr)) {
    return("@selections must contain only character vectors")
  }
  NULL
}

#' @keywords internal
as_collections <- function(x, call = rlang::caller_env()) {
  if (inherits(x, "conjoint_df")) {
    return(get_collections(x))
  }
  is_collection <- function(e) S7::S7_inherits(e, collection)
  if (is.list(x) && length(x) > 0 && all(purrr::map_lgl(x, is_collection))) {
    return(x)
  }
  cli::cli_abort(
    c(
      "x" = "{.arg x} must be a {.cls conjoint_df} or a list of collections.",
      "i" = "You supplied {.obj_type_friendly {x}}."
    ),
    call = call
  )
}

#' @keywords internal
group_levels <- function(x, levels, call = rlang::caller_env()) {
  collections <- as_collections(x, call = call)
  collection_names <- purrr::map_chr(collections, \(cl) cl@name)
  level_sets <- purrr::map(collections, collection_levels)

  unknown <- setdiff(levels, purrr::list_c(level_sets))
  if (length(unknown) > 0) {
    cli::cli_abort(
      c(
        "x" = "Unknown level{?s} {.val {unknown}}.",
        "!" = "Every level must belong to a collection of {.arg x}.",
        "i" = "Available levels: {.val {purrr::list_c(level_sets)}}."
      ),
      call = call
    )
  }

  # An additive combine_fn would double-count a repeated level, so reject
  # duplicates rather than silently deduplicating them.
  dup <- unique(levels[duplicated(levels)])
  if (length(dup) > 0) {
    cli::cli_abort(
      c(
        "x" = "{cli::qty(dup)}Level{?s} {.val {dup}} {?is/are} selected more than once.",
        "!" = "Each level may appear at most once in {.arg levels}."
      ),
      call = call
    )
  }

  selections <- purrr::map(level_sets, \(lv) levels[levels %in% lv])
  names(selections) <- collection_names

  # An absence level ("No camera") represents having none of the feature, so it
  # cannot be co-selected with any other level from the same collection.
  absence_levels <- purrr::map(collections, collection_absence)
  conflicts <- purrr::map2_chr(selections, absence_levels, \(sel, abs) {
    if (length(abs) == 1 && abs %in% sel && length(sel) > 1) {
      abs
    } else {
      NA_character_
    }
  })
  conflicts <- conflicts[!is.na(conflicts)]
  if (length(conflicts) > 0) {
    cli::cli_abort(
      c(
        "x" = "{cli::qty(conflicts)}Absence level{?s} {.val {conflicts}} cannot be combined with other levels.",
        "!" = "An absence level must be selected on its own within its collection."
      ),
      call = call
    )
  }

  empty <- collection_names[lengths(selections) == 0]
  if (length(empty) > 0) {
    cli::cli_warn("No levels selected for collection{?s} {.field {empty}}.")
  }
  selections
}

# Render a product to a character vector of cli-formatted lines. Kept separate
# from the print method so competitive_set can reuse it *with* styling intact -
# cli_fmt() preserves colour and weight, unlike capturing printed output.
#' @keywords internal
format_product <- function(x) {
  label <- if (length(x@name) == 1) x@name else "(unnamed)"
  cli::cli_fmt({
    cli::cli_text("{.cls product} {fmt_object_name(label)}")
    for (nm in names(x@selections)) {
      chosen <- x@selections[[nm]]
      value <- if (length(chosen) == 0) {
        fmt_annotation("\u2014")
      } else {
        cli::ansi_collapse(fmt_level(chosen))
      }
      cli::cli_li("{fmt_collection(nm)}: {value}")
    }
  })
}

S7::method(print, product) <- function(x, ...) {
  cat(format_product(x), sep = "\n")
  invisible(x)
}
