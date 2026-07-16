#' Bundle specifications into a competitive set
#'
#' A `competitive_set` is an ordered list of [product]s that compete for share in a
#' scenario. All products must reference the same set of collections.
#'
#' @param ... [product] objects that compete for share. Pass them individually;
#'   they are collected into the set's `products`.
#' @param name An optional single string naming the set.
#' @param none Whether the NONE outside good ("choose nothing") competes for
#'   share alongside the set's products. Defaults to `TRUE`. Passed through to
#'   [run_scenario()].
#'
#' @return A `competitive_set` object.
#' @examples
#' cjt <- conjoint_df(example_utilities, example_crosswalk)
#' competitive_set(
#'   product(cjt, c("Northwind", "$299", "20 hours", "256 GB", "Black"), name = "Flagship"),
#'   product(cjt, c("Cascade", "$199", "10 hours", "128 GB", "Blue"), name = "Budget"),
#'   name = "Launch"
#' )
#'
#' # Exclude the NONE outside good, forcing a choice between the products.
#' competitive_set(
#'   product(cjt, c("Northwind", "$299", "20 hours", "256 GB", "Black"), name = "Flagship"),
#'   product(cjt, c("Cascade", "$199", "10 hours", "128 GB", "Blue"), name = "Budget"),
#'   name = "Launch",
#'   none = FALSE
#' )
#' @export
competitive_set <- S7::new_class(
  "competitive_set",
  properties = list(
    name = S7::class_character,
    products = S7::class_list,
    none = S7::class_logical
  ),
  constructor = function(..., name = character(), none = TRUE) {
    S7::new_object(
      S7::S7_object(),
      name = name,
      products = list(...),
      none = none
    )
  },
  validator = function(self) {
    validate_competitive_set(self@name, self@products, self@none)
  }
)

# Defined at top level so `competitive_set` resolves to the S7 class (not a
# shadowing argument, as happens inside run_scenario()).
#' @keywords internal
is_competitive_set <- function(x) {
  S7::S7_inherits(x, competitive_set)
}

#' @keywords internal
validate_competitive_set <- function(name, products, none) {
  if (length(name) > 1) {
    return("@name must be a single string or empty")
  }
  if (length(products) == 0) {
    return("@products must contain at least one product")
  }
  is_product <- purrr::map_lgl(products, \(p) S7::S7_inherits(p, product))
  if (!all(is_product)) {
    return("@products must contain only product objects")
  }
  key_sets <- purrr::map(products, \(p) sort(names(p@selections)))
  if (length(unique(key_sets)) > 1) {
    return("all products must reference the same collections")
  }
  if (length(none) != 1 || is.na(none)) {
    return("@none must be a single TRUE or FALSE")
  }
  NULL
}

S7::method(print, competitive_set) <- function(x, ...) {
  products <- x@products
  label <- if (length(x@name) == 1) x@name else "(unnamed)"

  named <- purrr::map_chr(products, function(p) {
    if (length(p@name) == 1 && nzchar(p@name)) p@name else NA_character_
  })
  named_names <- named[!is.na(named)]
  n_unnamed <- sum(is.na(named))
  unnamed_phrase <- paste0(
    n_unnamed,
    " unnamed product",
    if (n_unnamed == 1) "" else "s"
  )
  # Green product names to match their own print method; cli collapses this
  # vector with commas and a trailing "and".
  descriptor <- c(
    fmt_object_name(named_names),
    if (n_unnamed > 0) unnamed_phrase
  )

  # cli_fmt() may wrap this into more than one line, so it is built as its own
  # vector of lines and joined into the rest of the output below - concatenating
  # pieces with cat(..., sep = "") would silently swallow the space at a wrap
  # point.
  header <- cli::cli_fmt(
    cli::cli_text(
      "{.cls competitive_set} {.strong {label}}: {length(products)} product{?s}: {descriptor}"
    )
  )

  # Print each product indented so the set reads as a set of products. Reuse
  # format_product() (rather than capturing print output) so the products keep
  # the colour and bold weight of their own print method. Each gets a blank
  # line above it.
  body <- purrr::list_c(purrr::map(products, function(p) {
    c("", paste0("  ", format_product(p)))
  }))

  # NONE is not a product, so it gets its own indented entry (rather than going
  # through format_product()) when it competes in this set.
  none_lines <- if (length(x@none) == 1 && x@none) {
    c("", paste0("  ", fmt_object_name("NONE")))
  } else {
    character()
  }

  cat(c(header, body, none_lines), sep = "\n")
  invisible(x)
}
