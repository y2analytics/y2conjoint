# Shared inline styling for the package's print methods, so that collection
# names, level values, and object names look the same wherever they appear.
# Keeping them here (rather than inlining cli calls in each print method) is what
# guarantees a product printed on its own looks identical to one printed inside a
# competitive_set.

#' @keywords internal
fmt_collection <- function(x) {
  cli::style_bold(cli::make_ansi_style("orange")(x))
}

# Level (column) names: cyan. Levels can be long and contain parentheses, so
# colouring them keeps them distinct from any annotation printed alongside.
#' @keywords internal
fmt_level <- function(x) {
  cli::make_ansi_style("cyan3")(x)
}

# Object names (a product's or set's name): bold green.
#' @keywords internal
fmt_object_name <- function(x) {
  cli::style_bold(cli::make_ansi_style("green4")(x))
}

# A dim annotation appended to a value, e.g. "(absence)" or "(ordered)".
#' @keywords internal
fmt_annotation <- function(x) {
  cli::make_ansi_style("grey")(x)
}
