#' Collections of conjoint levels
#'
#' A collection groups the columns of a [conjoint_df] that belong to a single
#' conjoint attribute (e.g. all `Brand` levels). An `ordered_collection` is a
#' collection whose levels have a meaningful order; the order is recorded by the
#' order of `levels` (there is no enforcement of that order elsewhere yet).
#'
#' @param name A single string naming the collection.
#' @param levels A character vector of the level (column) names that make up the
#'   collection.
#' @param absence An optional single level name marking the "absence" level of
#'   the collection - the level that represents having none of the feature (e.g.
#'   `"No camera"` in a `Camera` collection). It must be one of `levels`.
#'   Defaults to `character()` (no absence level).
#' @param order For `ordered_collection`, a character vector giving the levels
#'   in their intended order. It must contain exactly the same levels as
#'   `levels`. Defaults to `unique(levels)`, i.e. the order in which `levels`
#'   were supplied.
#'
#' @return A `collection` or `ordered_collection` object.
#' @examples
#' collection(name = "Brand", levels = c("Northwind", "Cascade"))
#'
#' # Flag the level that represents having none of the feature.
#' collection(
#'   name = "Camera",
#'   levels = c("No camera", "8 MP", "12 MP"),
#'   absence = "No camera"
#' )
#'
#' # By default the level order is taken from `levels`.
#' ordered_collection(name = "Price", levels = c("$199", "$299", "$399"))
#'
#' # Supply `order` to rank levels independently of how they were listed.
#' ordered_collection(
#'   name = "Price",
#'   levels = c("$399", "$199", "$299"),
#'   order = c("$199", "$299", "$399")
#' )
#' @export
collection <- S7::new_class(
  "collection",
  properties = list(
    name = S7::class_character,
    levels = S7::class_character,
    absence = S7::class_character
  ),
  validator = function(self) {
    validate_collection_fields(self@name, self@levels, self@absence)
  }
)

#' @rdname collection
#' @export
ordered_collection <- S7::new_class(
  "ordered_collection",
  parent = collection,
  properties = list(
    order = S7::class_character
  ),
  constructor = function(
    name,
    levels,
    order = unique(levels),
    absence = character()
  ) {
    S7::new_object(
      collection(name = name, levels = levels, absence = absence),
      order = order
    )
  },
  validator = function(self) {
    validate_order(self@order, self@levels)
  }
)

#' @keywords internal
validate_order <- function(order, levels) {
  if (length(order) != length(levels) || !setequal(order, levels)) {
    return("@order must contain exactly the same levels as @levels")
  }
  NULL
}

#' @keywords internal
validate_collection_fields <- function(name, levels, absence = character()) {
  if (length(name) != 1 || is.na(name) || !nzchar(name)) {
    return("@name must be a single non-empty string")
  }
  if (length(levels) == 0) {
    return("@levels must contain at least one level")
  }
  if (anyNA(levels) || !all(nzchar(levels))) {
    return("@levels must not contain missing or empty strings")
  }
  if (anyDuplicated(levels)) {
    return("@levels must be unique")
  }
  if (length(absence) > 1) {
    return("@absence must be a single level or empty")
  }
  if (length(absence) == 1 && !absence %in% levels) {
    return("@absence must be one of @levels")
  }
  NULL
}

#' Is a collection ordered?
#'
#' @param x A [collection] object.
#' @return A single logical.
#' @examples
#' is_ordered(collection("Brand", c("Northwind", "Cascade")))
#' is_ordered(ordered_collection("Price", c("$199", "$299", "$399")))
#' @export
is_ordered <- function(x) {
  S7::S7_inherits(x, ordered_collection)
}

#' @keywords internal
collection_levels <- function(x) {
  x@levels
}

#' @keywords internal
collection_absence <- function(x) {
  x@absence
}

S7::method(print, collection) <- function(x, ...) {
  ordered <- if (is_ordered(x)) fmt_annotation(" (ordered)") else ""
  levels <- if (is_ordered(x)) x@order else x@levels
  # Colour the level names; mark the absence level with a dim annotation so it
  # cannot be mistaken for part of the (possibly parenthesised) level name.
  labels <- fmt_level(levels)
  is_absence <- levels %in% x@absence
  labels[is_absence] <- paste0(
    labels[is_absence],
    " ",
    fmt_annotation("(absence)")
  )
  cat(
    cli::cli_fmt({
      cli::cli_text("{.cls collection} {fmt_collection(x@name)}{ordered}")
      cli::cli_ul(labels)
    }),
    sep = "\n"
  )
  invisible(x)
}
