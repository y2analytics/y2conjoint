#' Crosswalks: mapping model columns to collections
#'
#' A crosswalk is a data frame that tells [conjoint_df()] how the model-format
#' columns of a utilities data frame map to user-facing level names and to the
#' [collection]s (conjoint attributes) they belong to.
#'
#' @details
#' Each row of a crosswalk describes one level column:
#'
#' * `old_name`: the model-format column name, `A[NUM]B[NUM]`, as it appears in
#'   the utilities data.
#' * `user_name`: the name the column takes after [conjoint_df()] renames it.
#'   Must be unique across the crosswalk.
#' * `collection_name`: the attribute the level belongs to, e.g. `"Brand"`.
#' * `collection_order`: an integer rank giving the level's position in an
#'   ordered collection, or `NA` for an unordered collection. A collection must
#'   be either fully ranked or fully `NA`; partial ranks are an error.
#' * `absence` (optional): a logical flag marking the level that means the
#'   attribute is absent (see [collection]). At most one level per collection may
#'   be flagged. If the column is missing, no level is treated as absence.
#'
#' All of `old_name`, `user_name`, and `collection_name` must be character.
#' Every `old_name` must be a column of the utilities data, and each `old_name`
#' may appear only once. Columns of the utilities data that are not listed in the
#' crosswalk (e.g. IDs or demographics) are left unchanged.
#'
#' The crosswalk is coerced to a tibble, so `$` and `[[` do not partially match
#' column names.
#'
#' @seealso [conjoint_df()] builds a conjoint data frame from a crosswalk,
#'   [collection] and [ordered_collection()] describe the collections it creates,
#'   and [example_crosswalk] is a worked example.
#' @examples
#' head(example_crosswalk)
#'
#' conjoint_df(example_utilities, example_crosswalk)
#' @name crosswalk
NULL
