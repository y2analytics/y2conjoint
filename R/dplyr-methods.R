#' @importFrom dplyr dplyr_reconstruct dplyr_col_modify
#' @importFrom rlang %||%
#' @importFrom haven as_factor
NULL

# The haven importFrom above is deliberate: it forces haven's namespace (and its
# `.onLoad` vctrs S3 registration for `haven_labelled`) to load with the package.
# Without it, the column-type abbreviation printed for labelled columns is
# nondeterministic across test order and load state (`int+lbl` vs. the
# `hvn_lbll` fallback), which breaks print snapshots on CI.

# These dplyr verbs are thin pass-throughs. They exist only to record which verb
# the user called (a "sentinel" in the method's frame) so that abort_protected()
# can blame `select()`/`mutate()`/etc. rather than the internal machinery
# (`dplyr_col_modify()`, `names<-`) that dplyr routes protected-column edits
# through. Each immediately calls NextMethod(), so behaviour is unchanged.

#' @exportS3Method dplyr::mutate
mutate.conjoint_df <- function(.data, ...) {
  mark_dplyr_verb(sys.call(-1))
  NextMethod()
}

#' @exportS3Method dplyr::select
select.conjoint_df <- function(.data, ...) {
  mark_dplyr_verb(sys.call(-1))
  NextMethod()
}

#' @exportS3Method dplyr::rename
rename.conjoint_df <- function(.data, ...) {
  mark_dplyr_verb(sys.call(-1))
  NextMethod()
}

#' @exportS3Method dplyr::rename_with
rename_with.conjoint_df <- function(.data, ...) {
  mark_dplyr_verb(sys.call(-1))
  NextMethod()
}

# transmute() would silently drop the protected columns (it copies attributes
# without going through dplyr_reconstruct), so it is unsupported. It is also
# superseded, so we point users at the modern alternatives.
#' @exportS3Method dplyr::transmute
transmute.conjoint_df <- function(.data, ...) {
  cli::cli_abort(
    c(
      "x" = "{.fn transmute} is not supported for a {.cls conjoint_df}.",
      "!" = "It would drop the protected level and {.field NONE} columns.",
      "i" = "Use {.code mutate(..., .keep = 'none')} to keep only new columns.",
      "i" = "Or call {.fn tibble::as_tibble} first to drop the structure."
    ),
    call = sys.call(-1)
  )
}

# Record the user-facing verb call in the calling method's frame.
#' @keywords internal
mark_dplyr_verb <- function(call, frame = rlang::caller_env()) {
  assign(".conjoint_verb", call, envir = frame)
}

# Walk the call stack for the nearest recorded verb sentinel, if any.
#' @keywords internal
dplyr_verb_call <- function() {
  for (frame in sys.frames()) {
    if (exists(".conjoint_verb", envir = frame, inherits = FALSE)) {
      return(get(".conjoint_verb", envir = frame, inherits = FALSE))
    }
  }
  NULL
}

#' @keywords internal
abort_protected <- function(
  cols,
  action,
  call = dplyr_verb_call() %||% rlang::caller_env()
) {
  cli::cli_abort(
    c(
      "x" = "Can't {action} the protected column{?s}: {.field {cols}}.",
      "!" = "The {.field NONE} column and columns that are part of a collection in a {.cls conjoint_df} are protected.",
      "i" = "Convert to a tibble with {.fn tibble::as_tibble} to edit them."
    ),
    call = call
  )
}

#' @keywords internal
reattach_conjoint <- function(data, template) {
  new_conjoint_df(
    data,
    collections = get_collections(template),
    none = get_none(template)
  )
}

#' @exportS3Method dplyr::dplyr_reconstruct
dplyr_reconstruct.conjoint_df <- function(data, template) {
  protected <- protected_cols(template)
  dropped <- setdiff(protected, names(data))
  if (length(dropped) > 0) {
    abort_protected(dropped, "drop or rename")
  }
  reattach_conjoint(data, template)
}

#' @exportS3Method dplyr::dplyr_col_modify
dplyr_col_modify.conjoint_df <- function(data, cols) {
  clash <- intersect(names(cols), protected_cols(data))
  if (length(clash) > 0) {
    abort_protected(clash, "overwrite")
  }
  NextMethod()
}

#' @export
`$<-.conjoint_df` <- function(x, name, value) {
  if (name %in% protected_cols(x)) {
    abort_protected(name, "overwrite")
  }
  NextMethod()
}

#' @export
`[[<-.conjoint_df` <- function(x, i, value) {
  target <- if (is.character(i)) i else names(x)[i]
  clash <- intersect(target, protected_cols(x))
  if (length(clash) > 0) {
    abort_protected(clash, "overwrite")
  }
  NextMethod()
}

#' @export
`names<-.conjoint_df` <- function(x, value) {
  dropped <- setdiff(protected_cols(x), value)
  if (length(dropped) > 0) {
    abort_protected(dropped, "drop or rename")
  }
  NextMethod()
}

#' @export
`[.conjoint_df` <- function(x, ...) {
  out <- NextMethod()
  if (is.data.frame(out) && all(protected_cols(x) %in% names(out))) {
    return(reattach_conjoint(out, x))
  }
  out
}
