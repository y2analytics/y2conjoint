#' A data frame carrying collections of columns
#'
#' A `collected_df` is a tibble subclass that carries a list of [collection]s as
#' metadata: each collection names a group of columns that belong together. It is
#' the base type behind [conjoint_df] (which adds an outside-good column and
#' column protection) and is also what [run_scenario()] returns, where each
#' collection groups the `share_*` columns produced by one [competitive_set].
#'
#' Unlike a `conjoint_df`, a plain `collected_df` does not protect its columns:
#' ordinary dplyr and base operations may freely edit them. The class is
#' preserved through dplyr verbs where possible; if an operation removes some of
#' a collection's columns, that collection is dropped (with a warning) rather
#' than left dangling.
#'
#' @param data A data frame. It is coerced to a tibble internally.
#' @param collections The [collection]s that group the columns of `data`. Accepts
#'   a single [collection], a vector of them (via [c()]), or a list. Every level
#'   of every collection must be a column of `data`.
#'
#' @return A `collected_df`.
#' @examples
#' shares <- tibble::tibble(share_A = 0.4, share_B = 0.6)
#'
#' # A single collection need not be wrapped in a list.
#' collected_df(shares, collection("Launch", c("share_A", "share_B")))
#'
#' # Several collections can be passed as a vector or a list.
#' two <- tibble::tibble(share_A = 0.4, share_B = 0.6)
#' collected_df(two, c(collection("A", "share_A"), collection("B", "share_B")))
#' @export
collected_df <- function(data, collections) {
  data <- tibble::as_tibble(data)
  # Accept a bare collection or a c()/list of them.
  if (S7::S7_inherits(collections, collection)) {
    collections <- list(collections)
  }
  validate_collected_input(data, collections)
  new_collected_df(data, collections)
}

#' @keywords internal
new_collected_df <- function(data, collections) {
  tibble::new_tibble(
    data,
    collections = collections,
    nrow = nrow(data),
    class = "collected_df"
  )
}

#' @keywords internal
validate_collected_input <- function(
  data,
  collections,
  call = rlang::caller_env()
) {
  is_collection <- purrr::map_lgl(collections, \(cl) {
    S7::S7_inherits(cl, collection)
  })
  if (
    !is.list(collections) || (length(collections) > 0 && !all(is_collection))
  ) {
    cli::cli_abort(
      "{.arg collections} must be a {.cls collection}, or a vector or list of them.",
      call = call
    )
  }
  used <- purrr::list_c(purrr::map(collections, collection_levels))
  missing <- setdiff(used, names(data))
  if (length(missing) > 0) {
    cli::cli_abort(
      c(
        "x" = "{cli::qty(missing)}Collection level{?s} {.field {missing}} {?is/are} not {?a column/columns} of {.arg data}.",
        "!" = "Every collection level must name a column of {.arg data}."
      ),
      call = call
    )
  }
  invisible()
}

#' @keywords internal
is_collected_df <- function(x) {
  inherits(x, "collected_df")
}

#' The collections of a collected data frame
#'
#' Returns the list of [collection]s carried by a [collected_df] (including a
#' [conjoint_df], which is a `collected_df`). Each collection names a group of
#' columns that belong together - the conjoint attributes of a `conjoint_df`, or
#' the `share_*` columns of one [competitive_set] in a [run_scenario()] result.
#'
#' @param x A [collected_df].
#' @param call The calling environment, used to report errors. Defaults to the
#'   caller of `get_collections()`.
#'
#' @return A list of [collection] objects.
#' @examples
#' # A conjoint_df carries one collection per attribute.
#' cjt <- conjoint_df(example_utilities, example_crosswalk)
#' get_collections(cjt)
#'
#' # A run_scenario() result carries one collection per competitive set.
#' market <- competitive_set(
#'   product(cjt, c("Northwind", "$199", "20 hours", "256 GB", "Black"), name = "Value"),
#'   product(cjt, c("Meridian", "$399", "30 hours", "512 GB", "Black"), name = "Premium"),
#'   name = "Launch"
#' )
#' get_collections(run_scenario(cjt, market))
#' @export
get_collections <- function(x, call = rlang::caller_env()) {
  if (!is_collected_df(x)) {
    cli::cli_abort(
      "{.arg x} must be a {.cls collected_df}.",
      call = call
    )
  }
  attr(x, "collections")
}

# Render the collection list shared by the collected_df and conjoint_df print
# methods, so a collection looks the same wherever it is listed. One collection
# per line, ordered ones marked with a dim annotation.
#' @keywords internal
format_collections_list <- function(collections) {
  names <- purrr::map_chr(collections, \(cl) cl@name)
  ordered <- purrr::map_lgl(collections, is_ordered)
  labels <- fmt_collection(names)
  labels[ordered] <- paste0(labels[ordered], fmt_annotation(" (ordered)"))
  labels
}

# Registered as the print method for collected_df in .onLoad() (see zzz.R), for
# the same reason print.conjoint_df is registered manually there.
print_collected_df <- function(x, ...) {
  collections <- get_collections(x)
  labels <- format_collections_list(collections)
  in_collection <- purrr::list_c(purrr::map(collections, collection_levels))
  n_other <- ncol(x) - length(unique(in_collection))

  cat(
    cli::cli_fmt({
      cli::cli_text("{.cls collected_df}: {length(collections)} collection{?s}")
      cli::cli_ul(labels)
      if (n_other > 0) {
        cli::cli_text("{n_other} column{?s} not in a collection")
      }
    }),
    sep = "\n"
  )
  print(unclass_collected(x), ...)
  invisible(x)
}

#' @keywords internal
unclass_collected <- function(x) {
  class(x) <- setdiff(class(x), c("conjoint_df", "collected_df"))
  x
}

# Keep only the collections whose levels are all still present, warning about any
# that are dropped because an operation removed some of their columns.
#' @keywords internal
surviving_collections <- function(collections, cols) {
  keep <- purrr::map_lgl(collections, \(cl) {
    all(collection_levels(cl) %in% cols)
  })
  if (!all(keep)) {
    dropped <- purrr::map_chr(collections[!keep], \(cl) cl@name)
    cli::cli_warn(c(
      "!" = "Dropped {cli::qty(dropped)}collection{?s} {.field {dropped}} from the {.cls collected_df}.",
      "i" = "{cli::qty(dropped)}Not all of {?its/their} columns are still present."
    ))
  }
  collections[keep]
}

#' @exportS3Method dplyr::dplyr_reconstruct
dplyr_reconstruct.collected_df <- function(data, template) {
  collections <- surviving_collections(
    get_collections(template),
    names(data)
  )
  new_collected_df(data, collections)
}

#' @export
`[.collected_df` <- function(x, ...) {
  out <- NextMethod()
  # When reached via NextMethod() from `[.conjoint_df`, let that method own the
  # result (it reattaches or drops the conjoint structure itself); wrapping here
  # would prematurely fire the drop-collection warning.
  if (inherits(x, "conjoint_df")) {
    return(out)
  }
  if (is.data.frame(out)) {
    collections <- surviving_collections(get_collections(x), names(out))
    return(new_collected_df(out, collections))
  }
  out
}
