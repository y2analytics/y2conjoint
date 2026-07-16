#' Compute the total utility of a product
#'
#' A product is described by a [product], which selects one or more levels from
#' each collection (attribute). This function turns that description into a
#' single utility per respondent by:
#' 1. combining the selected levels *within* each collection into one value
#'    (e.g. [pmax()] takes the best available level, which is how co-branded
#'    products that list two brands are handled), and
#' 2. summing those per-collection values *across* collections.
#'
#' @param x A [conjoint_df].
#' @param product A [product].
#' @param combine_fn How to combine multiple selected levels within a collection.
#'   Either a single function applied to every collection (the default,
#'   [pmax()]), or a named list mapping collection names to functions. Any
#'   collection absent from the list falls back to [pmax()].
#'
#' @return A numeric vector, one utility per row of `x`.
#' @examples
#' cjt <- conjoint_df(example_utilities, example_crosswalk)
#' flagship <- product(
#'   cjt,
#'   c("Northwind", "$299", "20 hours", "256 GB", "Black"),
#'   name = "Flagship"
#' )
#' head(compute_product_utility(cjt, flagship))
#'
#' # Sum the brand levels of a co-branded product instead of taking the best.
#' co_brand <- product(
#'   cjt,
#'   c("Northwind", "Cascade", "$199", "20 hours", "256 GB", "Black")
#' )
#' head(compute_product_utility(cjt, co_brand, combine_fn = list(Brand = `+`)))
#' @export
compute_product_utility <- function(x, product, combine_fn = pmax) {
  # Keep only the collections this product actually selects a level from.
  selections <- purrr::keep(product@selections, \(levels) length(levels) > 0)

  # A product that selects nothing has zero utility for everyone.
  if (length(selections) == 0) {
    return(rep(0, nrow(x)))
  }

  # For each collection, combine its selected level columns into one utility
  # vector, then sum those vectors to get the product's total utility.
  per_collection <- purrr::imap(selections, function(levels, collection) {
    combine <- resolve_combine_fn(combine_fn, collection)
    level_utilities <- purrr::map(levels, \(level) x[[level]])
    rlang::inject(combine(!!!level_utilities))
  })
  purrr::reduce(per_collection, `+`)
}

#' Estimate preference shares for a competitive set
#'
#' Applies a logit (softmax) choice model: each respondent's utility for every
#' product is turned into a probability of choosing it, and those probabilities
#' are averaged across respondents to give each product's mean preference share.
#' The NONE outside good competes for share as a "choose nothing" option.
#'
#' @param x A [conjoint_df] of individual-level utilities.
#' @param competitive_set A [competitive_set], or a list of them. When a list is
#'   supplied, the scenario is run on each set individually and the results are
#'   column-bound together. Any `share_*` column name shared by more than one set
#'   is disambiguated by appending `_i`, where `i` is the 1-based position of the
#'   set it came from (unique names are left untouched).
#' @param combine_fn How to combine multiple selected levels within a collection.
#'   Either a single function applied to every collection (the default,
#'   [pmax()]), or a named list mapping collection names to functions. Any
#'   collection absent from the list falls back to [pmax()].
#' @param scaling_factor A numeric multiplier applied to all utilities before the
#'   softmax. Values above 1 sharpen the choice probabilities toward the highest
#'   utility; values below 1 flatten them. Defaults to `1`.
#' @param .by Optional <[`tidy-select`][dplyr::dplyr_tidy_select]> columns to
#'   compute shares within. Each selected column is treated *marginally*: the
#'   sample is split by that column's values and shares are computed within each
#'   value, then the results for every selected column are stacked. Defaults to
#'   `NULL` (whole sample).
#'
#' @return A [collected_df]: the `share_*` columns produced by the
#'   competitive set(s), with one [collection] per set grouping that set's
#'   columns (named after the set, or `set_i` when unnamed). When `.by` is
#'   `NULL` it has one row; when `.by` is supplied it carries `group_var` (the
#'   grouping column), `group_level` (its value, as a string), and `n`
#'   (respondents in the subgroup) alongside the `share_*` columns, one row per
#'   grouping variable and value.
#' @examples
#' cjt <- conjoint_df(example_utilities, example_crosswalk)
#' market <- competitive_set(
#'   product(cjt, c("Northwind", "$199", "20 hours", "256 GB", "Black"), name = "Value"),
#'   product(cjt, c("Meridian", "$399", "30 hours", "512 GB", "Black"), name = "Premium"),
#'   name = "Launch"
#' )
#' run_scenario(cjt, market)
#'
#' # Sharpen the shares toward the most attractive product.
#' run_scenario(cjt, market, scaling_factor = 2)
#'
#' # Shares within each region, then within each gender, stacked.
#' run_scenario(cjt, market, .by = c(region, gender))
#'
#' # Compare two competitive sets side by side.
#' refresh <- competitive_set(
#'   product(cjt, c("Cascade", "$299", "30 hours", "512 GB", "Blue"), name = "Value"),
#'   name = "Refresh"
#' )
#' run_scenario(cjt, list(market, refresh))
#' @export
run_scenario <- function(
  x,
  competitive_set,
  combine_fn = pmax,
  scaling_factor = 1,
  .by = NULL
) {
  sets <- normalize_competitive_sets(competitive_set)
  purrr::walk(sets, function(set) {
    check_products_columns(x, set@products)
  })
  check_combine_fn(combine_fn, x)
  # From here the inputs are validated, so the rest is pure computation.

  by_vars <- names(tidyselect::eval_select(rlang::enquo(.by), x))

  # Score each set on its own, then stitch the per-set results together.
  per_set <- purrr::map(sets, function(set) {
    run_one_scenario(x, set@products, combine_fn, scaling_factor, by_vars)
  })
  combine_scenarios(per_set, sets)
}

# Accept either a single competitive_set or a list of them, and validate that a
# list holds only competitive_set objects.
#' @keywords internal
normalize_competitive_sets <- function(x, call = rlang::caller_env()) {
  if (is_competitive_set(x)) {
    return(list(x))
  }
  if (
    !is.list(x) || length(x) == 0 || !all(purrr::map_lgl(x, is_competitive_set))
  ) {
    cli::cli_abort(
      c(
        "x" = "{.arg competitive_set} must be a {.cls competitive_set} or a non-empty list of them.",
        "i" = "You supplied {.obj_type_friendly {x}}."
      ),
      call = call
    )
  }
  x
}

# Score one competitive set. Without grouping this is a one-row tibble of shares;
# with grouping it carries group_var/group_level/n columns per subgroup.
#' @keywords internal
run_one_scenario <- function(x, products, combine_fn, scaling_factor, by_vars) {
  if (length(by_vars) == 0) {
    return(scenario_shares(x, products, combine_fn, scaling_factor))
  }

  # Treat each grouping column marginally: split the sample by its values,
  # score every subgroup, and stack the per-column results.
  rows <- purrr::map(by_vars, function(var) {
    values <- x[[var]]
    # Survey data often arrives with SPSS-style value labels (a haven_labelled
    # column of integer codes). Group on the labels so the output reads in human
    # terms rather than as bare codes.
    if (inherits(values, "haven_labelled")) {
      values <- haven::as_factor(values)
    }
    purrr::map(subgroup_levels(values), function(level) {
      in_group <- if (is.na(level)) {
        is.na(values)
      } else {
        !is.na(values) & values == level
      }
      subgroup <- dplyr::filter(x, in_group)
      dplyr::bind_cols(
        tibble::tibble(
          group_var = var,
          group_level = as.character(level),
          n = nrow(subgroup)
        ),
        scenario_shares(subgroup, products, combine_fn, scaling_factor)
      )
    })
  })
  dplyr::bind_rows(purrr::list_flatten(rows))
}

# Column-bind the per-set results into one collected_df: keep any grouping
# columns once (they are identical across sets, which are scored on the same
# sample), disambiguate share names shared by more than one set with a `_i`
# suffix, and record one collection per set.
#' @keywords internal
combine_scenarios <- function(per_set, sets) {
  is_share <- \(nms) startsWith(nms, "share_")
  share_by_set <- purrr::map(per_set, \(tbl) names(tbl)[is_share(names(tbl))])

  # A share name appearing in more than one set is renamed in every set it
  # appears in; unique names are left untouched.
  all_share <- purrr::list_c(share_by_set)
  colliding <- unique(all_share[duplicated(all_share)])

  renamed <- purrr::imap(per_set, function(tbl, i) {
    shares <- share_by_set[[i]]
    new_shares <- dplyr::if_else(
      shares %in% colliding,
      paste0(shares, "_", i),
      shares
    )
    names(tbl)[match(shares, names(tbl))] <- new_shares
    tbl
  })

  # Grouping columns (group_var/group_level/n) are identical across sets, so keep
  # the first set's copy and bind only the share columns from the rest.
  first <- renamed[[1]]
  if (length(renamed) > 1) {
    others <- purrr::map(renamed[-1], \(tbl) tbl[is_share(names(tbl))])
    combined <- dplyr::bind_cols(first, !!!others)
  } else {
    combined <- first
  }

  collections <- purrr::imap(renamed, function(tbl, i) {
    set <- sets[[i]]
    name <- if (length(set@name) == 1 && nzchar(set@name)) {
      set@name
    } else {
      paste0("set_", i)
    }
    collection(name = name, levels = names(tbl)[is_share(names(tbl))])
  })

  new_collected_df(combined, collections)
}

# The distinct values of a grouping column, in the order subgroups should be
# reported. Factors (including converted labelled columns) keep their level
# order and drop unused levels; other types are sorted. A missing value, when
# present, becomes its own subgroup listed last.
#' @keywords internal
subgroup_levels <- function(values) {
  if (is.factor(values)) {
    present <- intersect(levels(values), as.character(values))
    if (anyNA(values)) {
      present <- c(present, NA_character_)
    }
    return(present)
  }
  sort(unique(values), na.last = TRUE)
}

# Score one (sub)sample: one utility column per product plus NONE, softmax to
# per-respondent choice probabilities, then average to mean shares.
#' @keywords internal
scenario_shares <- function(x, products, combine_fn, scaling_factor) {
  # One utility column per product (rows = respondents).
  product_utilities <- purrr::map(
    products,
    \(product) compute_product_utility(x, product, combine_fn) * scaling_factor
  )
  names(product_utilities) <- product_output_names(products)

  # Add NONE as one more column so the "choose nothing" option competes with
  # the products for share.
  product_utilities[["none"]] <- x[[get_none(x)]] * scaling_factor

  # Convert utilities to per-respondent choice probabilities, then average
  # across respondents to get each option's mean share.
  utilities <- do.call(cbind, product_utilities)
  shares <- colMeans(softmax_rows(utilities))

  format_shares(shares)
}

# Softmax: convert a matrix of utilities into row-wise choice probabilities via
# the logit rule P(i) = exp(u_i) / sum_j exp(u_j).
#' @keywords internal
softmax_rows <- function(m) {
  # Subtract each row's largest utility before exponentiating. Large utilities
  # would overflow exp() to Inf; subtracting a per-row constant prevents that
  # and cancels in the ratio, so the probabilities are unchanged.
  row_max <- as.numeric(purrr::reduce(asplit(m, 2), pmax))
  weights <- exp(m - row_max)
  weights / rowSums(weights)
}

# Drop the outside good and return a one-row tibble of rounded product shares,
# one column per product in the competitive set.
#' @keywords internal
format_shares <- function(shares) {
  shares <- round(shares, 3)
  products <- shares[names(shares) != "none"]

  out <- tibble::as_tibble(as.list(products))
  names(out) <- paste0("share_", names(products))
  out
}

# Resolve the combine function for a single collection. `combine_fn` is either
# one function for every collection, or a named list keyed by collection name.
#' @keywords internal
resolve_combine_fn <- function(combine_fn, collection) {
  if (is.function(combine_fn)) {
    return(combine_fn)
  }
  fn <- combine_fn[[collection]]
  if (is.null(fn)) pmax else fn
}

# Name each product's output column after its own name, falling back to a
# positional name (product_1, product_2, ...) for unnamed products.
#' @keywords internal
product_output_names <- function(products) {
  purrr::imap_chr(products, function(product, i) {
    nm <- product@name
    if (length(nm) == 1 && nzchar(nm)) nm else paste0("product_", i)
  })
}

# Fail early if any product references a level that is not a column of `x`.
#' @keywords internal
check_products_columns <- function(x, products, call = rlang::caller_env()) {
  used <- unique(purrr::list_c(purrr::map(products, \(product) {
    purrr::list_c(product@selections)
  })))
  missing <- setdiff(used, names(x))
  if (length(missing) > 0) {
    cli::cli_abort(
      c(
        "x" = "The competitive set references {cli::qty(missing)}level{?s} that {?is/are} not in {.arg x}.",
        "!" = "Missing from {.arg x}: {.field {missing}}."
      ),
      call = call
    )
  }
}

# Validate the combine_fn argument: either a function, or a named list of
# functions whose names are all real collections of `x` (catches typos).
#' @keywords internal
check_combine_fn <- function(combine_fn, x, call = rlang::caller_env()) {
  if (is.function(combine_fn)) {
    return(invisible())
  }
  if (!is.list(combine_fn) || !is_fully_named(combine_fn)) {
    cli::cli_abort(
      c(
        "x" = "{.arg combine_fn} must be a function or a named list of functions.",
        "i" = "Name each element after the collection it combines."
      ),
      call = call
    )
  }
  not_function <- names(combine_fn)[!purrr::map_lgl(combine_fn, is.function)]
  if (length(not_function) > 0) {
    cli::cli_abort(
      c(
        "x" = "Every element of {.arg combine_fn} must be a function.",
        "!" = "Not {cli::qty(not_function)}{?a function/functions}: {.field {not_function}}."
      ),
      call = call
    )
  }
  known <- purrr::map_chr(get_collections(x), \(collection) {
    collection@name
  })
  unknown <- setdiff(names(combine_fn), known)
  if (length(unknown) > 0) {
    cli::cli_abort(
      c(
        "x" = "{.arg combine_fn} names {cli::qty(unknown)}collection{?s} not found in {.arg x}.",
        "!" = "Unknown: {.field {unknown}}."
      ),
      call = call
    )
  }
  invisible()
}

#' @keywords internal
is_fully_named <- function(x) {
  !is.null(names(x)) && all(nzchar(names(x)))
}
