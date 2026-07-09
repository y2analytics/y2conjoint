#' Bundle specifications into a competitive set
#'
#' A `competitive_set` is an ordered list of [spec]s that compete for share in a
#' scenario. All specs must reference the same set of collections.
#'
#' @param ... [spec] objects that compete for share. Pass them individually;
#'   they are collected into the set's `specs`.
#' @param name An optional single string naming the set.
#'
#' @return A `competitive_set` object.
#' @examples
#' cjt <- conjoint_df(example_utilities, example_crosswalk)
#' competitive_set(
#'   spec(cjt, c("Northwind", "$299", "20 hours", "256 GB", "Black"), name = "Flagship"),
#'   spec(cjt, c("Cascade", "$199", "10 hours", "128 GB", "Blue"), name = "Budget"),
#'   name = "Launch"
#' )
#' @export
competitive_set <- S7::new_class(
  "competitive_set",
  properties = list(
    name = S7::class_character,
    specs = S7::class_list
  ),
  constructor = function(..., name = character()) {
    S7::new_object(S7::S7_object(), name = name, specs = list(...))
  },
  validator = function(self) {
    validate_competitive_set(self@name, self@specs)
  }
)

#' @keywords internal
validate_competitive_set <- function(name, specs) {
  if (length(name) > 1) {
    return("@name must be a single string or empty")
  }
  if (length(specs) == 0) {
    return("@specs must contain at least one spec")
  }
  is_spec <- purrr::map_lgl(specs, \(s) S7::S7_inherits(s, spec))
  if (!all(is_spec)) {
    return("@specs must contain only spec objects")
  }
  key_sets <- purrr::map(specs, \(s) sort(names(s@selections)))
  if (length(unique(key_sets)) > 1) {
    return("all specs must reference the same collections")
  }
  NULL
}

S7::method(print, competitive_set) <- function(x, ...) {
  specs <- x@specs
  label <- if (length(x@name) == 1) x@name else "(unnamed)"

  named <- purrr::map_chr(specs, function(s) {
    if (length(s@name) == 1 && nzchar(s@name)) s@name else NA_character_
  })
  named_names <- named[!is.na(named)]
  n_unnamed <- sum(is.na(named))
  unnamed_phrase <- paste0(
    n_unnamed,
    " unnamed spec",
    if (n_unnamed == 1) "" else "s"
  )
  # Green spec names to match their own print method; cli collapses this vector
  # with commas and a trailing "and".
  descriptor <- c(
    fmt_object_name(named_names),
    if (n_unnamed > 0) unnamed_phrase
  )

  cat(
    cli::cli_fmt(
      cli::cli_text(
        "{.cls competitive_set} {.strong {label}}: {length(specs)} spec{?s}: {descriptor}"
      )
    ),
    "\n",
    sep = ""
  )
  # Print each spec indented so the set reads as a set of products. Reuse
  # format_spec() (rather than capturing print output) so the specs keep the
  # colour and bold weight of their own print method.
  for (s in specs) {
    cat("\n")
    cat(paste0("  ", format_spec(s)), sep = "\n")
  }
  invisible(x)
}
