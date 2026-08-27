#' Create a conjoint data frame
#'
#' `conjoint_df()` builds a tibble subclass that carries its conjoint structure
#' as metadata. Utility columns arrive in the model format (`A[NUM]B[NUM]`) and
#' are renamed to their user-facing names; they are grouped into [collection]s
#' via the supplied `crosswalk`. Any columns not described by the crosswalk
#' (e.g. demographics or IDs) are kept as-is.
#'
#' The level columns and the `none` column are *protected*: dplyr and base
#' operations may freely edit other columns, but attempts to drop, rename, or
#' overwrite a protected column error. Convert with [tibble::as_tibble()] first
#' to escape those guards.
#'
#' @param data A data frame of individual-level utilities. Level columns are
#'   named in the model format `A[NUM]B[NUM]`; extra columns are allowed. It is
#'   coerced to a tibble internally.
#' @param crosswalk A data frame mapping levels to collections, with columns
#'   `old_name` (the model-format column), `user_name` (the renamed column),
#'   `collection_name`, and `collection_order` (an integer rank, or `NA` for
#'   unordered collections). An optional logical `absence` column flags the
#'   "absence" level of a collection (see [collection]); at most one level per
#'   collection may be flagged, and it defaults to no absence levels when the
#'   column is missing. It is coerced to a tibble internally, which gives
#'   stricter column access (no partial matching) than a base data frame.
#' @param none_col The name of the outside-good column. Defaults to `"NONE"`.
#'
#' @return A `conjoint_df`.
#' @examples
#' conjoint_df(example_utilities, example_crosswalk)
#' @export
conjoint_df <- function(data, crosswalk, none_col = "NONE") {
  data <- tibble::as_tibble(data)
  crosswalk <- tibble::as_tibble(crosswalk)

  validate_conjoint_input(data, crosswalk, none_col)

  data <- rename_to_user_names(data, crosswalk)
  collections <- build_collections(crosswalk)
  new_conjoint_df(data, collections = collections, none = none_col)
}

#' @keywords internal
new_conjoint_df <- function(data, collections, none) {
  # conjoint_df is a subclass of collected_df: it adds the outside-good column
  # and column protection on top of the collection metadata.
  tibble::new_tibble(
    data,
    collections = collections,
    none = none,
    nrow = nrow(data),
    class = c("conjoint_df", "collected_df")
  )
}

#' @keywords internal
crosswalk_columns <- function() {
  c("old_name", "user_name", "collection_name", "collection_order")
}

#' @keywords internal
validate_conjoint_input <- function(
  data,
  crosswalk,
  none,
  call = rlang::caller_env()
) {
  missing_cols <- setdiff(crosswalk_columns(), names(crosswalk))
  if (length(missing_cols) > 0) {
    cli::cli_abort(
      c(
        "x" = "{.arg crosswalk} is missing required column{?s} {.field {missing_cols}}.",
        "i" = "A crosswalk needs {.field {crosswalk_columns()}}."
      ),
      call = call
    )
  }
  validate_crosswalk_types(crosswalk, call = call)
  validate_collection_orders(crosswalk, call = call)
  validate_crosswalk_absence(crosswalk, call = call)
  missing_levels <- setdiff(crosswalk$old_name, names(data))
  if (length(missing_levels) > 0) {
    cli::cli_abort(
      c(
        "x" = "{.arg crosswalk} maps {cli::qty(missing_levels)}column{?s} {.field {missing_levels}} that {?is/are} not in {.arg data}.",
        "!" = "Every {.field old_name} must name a column of {.arg data}."
      ),
      call = call
    )
  }
  dup_old <- unique(crosswalk$old_name[duplicated(crosswalk$old_name)])
  if (length(dup_old) > 0) {
    cli::cli_abort(
      c(
        "x" = "Each {.field old_name} in {.arg crosswalk} must map to one collection.",
        "!" = "Assigned more than once: {.field {dup_old}}."
      ),
      call = call
    )
  }
  duplicates <- unique(crosswalk$user_name[duplicated(crosswalk$user_name)])
  if (length(duplicates) > 0) {
    cli::cli_abort(
      c(
        "x" = "{.field user_name} values in {.arg crosswalk} must be unique.",
        "!" = "Duplicated: {.field {duplicates}}."
      ),
      call = call
    )
  }
  # A user_name that matches a column we are not renaming would create two
  # columns with the same name after the rename.
  untouched <- setdiff(names(data), crosswalk$old_name)
  collisions <- intersect(crosswalk$user_name, untouched)
  if (length(collisions) > 0) {
    cli::cli_abort(
      c(
        "x" = "{cli::qty(collisions)}{.field user_name} value{?s} {.field {collisions}} would collide with existing column{?s} of {.arg data}.",
        "!" = "Renaming would create duplicate columns.",
        "i" = "Pick names that are not already columns of {.arg data}."
      ),
      call = call
    )
  }
  if (!none %in% names(data)) {
    cli::cli_abort(
      c(
        "x" = "{.arg none} column {.field {none}} is not in {.arg data}.",
        "i" = "Set {.arg none} to the name of your outside-good column."
      ),
      call = call
    )
  }
  invisible()
}

#' @keywords internal
validate_crosswalk_types <- function(crosswalk, call = rlang::caller_env()) {
  text_cols <- c("old_name", "user_name", "collection_name")
  is_text <- purrr::map_lgl(crosswalk[text_cols], is.character)
  if (!all(is_text)) {
    cli::cli_abort(
      c(
        "x" = "Column{?s} {.field {text_cols[!is_text]}} in {.arg crosswalk} must be character."
      ),
      call = call
    )
  }
  order <- crosswalk$collection_order
  if (!is.numeric(order) && !all(is.na(order))) {
    cli::cli_abort(
      c(
        "x" = "{.field collection_order} in {.arg crosswalk} must be numeric or {.val {NA}}.",
        "i" = "Use integer ranks for ordered collections and {.val {NA}} otherwise."
      ),
      call = call
    )
  }
}

# The optional `absence` column, when present, must be logical and flag at most
# one level per collection.
#' @keywords internal
validate_crosswalk_absence <- function(crosswalk, call = rlang::caller_env()) {
  if (!"absence" %in% names(crosswalk)) {
    return(invisible())
  }
  if (!is.logical(crosswalk$absence)) {
    cli::cli_abort(
      c(
        "x" = "{.field absence} in {.arg crosswalk} must be logical.",
        "i" = "Use {.val {TRUE}} for the absence level of a collection and {.val {FALSE}} otherwise."
      ),
      call = call
    )
  }
  flagged <- crosswalk$absence
  flagged[is.na(flagged)] <- FALSE
  per_collection <- tapply(flagged, crosswalk$collection_name, sum)
  multiple <- names(per_collection)[per_collection > 1]
  if (length(multiple) > 0) {
    cli::cli_abort(
      c(
        "x" = "{cli::qty(multiple)}Collection{?s} {.field {multiple}} {?has/have} more than one {.field absence} level.",
        "!" = "At most one level per collection may be flagged as absence."
      ),
      call = call
    )
  }
  invisible()
}

#' @keywords internal
validate_collection_orders <- function(crosswalk, call = rlang::caller_env()) {
  orders <- split(crosswalk$collection_order, crosswalk$collection_name)
  # A collection is either fully unordered (all NA) or fully ranked. A mix means
  # some levels were left without a rank.
  is_partial <- purrr::map_lgl(orders, \(order) {
    anyNA(order) && !all(is.na(order))
  })
  partial <- names(orders)[is_partial]
  if (length(partial) > 0) {
    cli::cli_abort(
      c(
        "x" = "{cli::qty(partial)}Collection{?s} {.field {partial}} {?has/have} a partial {.field collection_order}.",
        "!" = "Ordered collections need a rank for every level.",
        "i" = "Give every level an order, or set them all to {.val {NA}}."
      ),
      call = call
    )
  }
}

#' @keywords internal
rename_to_user_names <- function(data, crosswalk) {
  match_idx <- match(crosswalk$old_name, names(data))
  names(data)[match_idx] <- crosswalk$user_name
  data
}

#' @keywords internal
build_collections <- function(crosswalk) {
  collection_names <- unique(crosswalk$collection_name)
  purrr::map(collection_names, \(nm) {
    build_one_collection(crosswalk[crosswalk$collection_name == nm, ])
  })
}

# Assumes validate_collection_orders() and validate_crosswalk_absence() have
# already run, so the order is either all NA (unordered) or fully specified
# (ordered), and at most one level is flagged as absence.
#' @keywords internal
build_one_collection <- function(rows) {
  name <- rows$collection_name[[1]]
  absence <- collection_absence_from_rows(rows)
  order <- rows$collection_order
  if (all(is.na(order))) {
    return(collection(name = name, levels = rows$user_name, absence = absence))
  }
  ordered_collection(
    name = name,
    levels = rows$user_name,
    order = rows$user_name[order(order)],
    absence = absence
  )
}

# The user_name flagged as the absence level for these rows, or character() when
# there is no absence column or no flagged level.
#' @keywords internal
collection_absence_from_rows <- function(rows) {
  if (!"absence" %in% names(rows)) {
    return(character())
  }
  flagged <- rows$absence
  flagged[is.na(flagged)] <- FALSE
  rows$user_name[flagged]
}

#' @keywords internal
get_none <- function(x) {
  attr(x, "none")
}

#' Protected columns of a conjoint data frame
#'
#' The level columns of every collection plus the `none` column. These columns
#' cannot be dropped, renamed, or overwritten in place.
#'
#' @param x A [conjoint_df].
#' @return A character vector of column names.
#' @examples
#' cjt <- conjoint_df(example_utilities, example_crosswalk)
#' protected_cols(cjt)
#' @export
protected_cols <- function(x) {
  levels <- purrr::list_c(purrr::map(
    get_collections(x),
    collection_levels
  ))
  unique(c(levels, get_none(x)))
}

# Registered as the print method for conjoint_df in .onLoad(). We register
# manually (rather than via @export) because S7::methods_register() drops plain
# S3 methods on the print generic once S7 owns other print methods.
print_conjoint_df <- function(x, ...) {
  collections <- get_collections(x)
  # One collection per line; mark ordered ones with a dim annotation rather than
  # an asterisk and legend.
  labels <- format_collections_list(collections)
  n_extra <- ncol(x) - length(protected_cols(x))

  cat(
    cli::cli_fmt({
      cli::cli_text(
        "{.cls conjoint_df}: {length(collections)} collection{?s}"
      )
      cli::cli_ul(labels)
      cli::cli_text(
        "NONE = {.field {get_none(x)}}, {n_extra} extra column{?s}"
      )
    }),
    sep = "\n"
  )
  print(unclass_conjoint(x), ...)
  invisible(x)
}

#' @keywords internal
unclass_conjoint <- function(x) {
  class(x) <- setdiff(class(x), c("conjoint_df", "collected_df"))
  x
}
