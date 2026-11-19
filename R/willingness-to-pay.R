#' Willingness to pay for product changes
#'
#' Estimates how much more (or less) respondents would pay for a changed
#' version of a product. The reference [product] (A) is scored against the NONE
#' outside good to get its preference share. Each alternative (A') is then
#' scored the same way while its price is varied, and the price at which A''s
#' share equals A's is found. Willingness to pay is that price minus A's price:
#' positive when A' is worth a premium, negative when it needs a discount.
#'
#' Alternatives are described by `alternatives`:
#'
#' * `NULL` (the default) changes the reference one level at a time, exactly as
#'   [sensitivity_analysis()] does (price itself is skipped).
#' * A character vector of levels builds one alternative by swapping those
#'   levels into the reference. Every collection the levels touch is replaced by
#'   them; all other collections stay as they are.
#' * A [product] is used as the alternative as is.
#' * A list of any mix of the above builds several alternatives. Names on the
#'   list label the output rows.
#'
#' The price of an alternative is always solved for, so any price level in an
#' alternative is ignored with a warning if it differs from the reference.
#'
#' @section Matching:
#' Price is only measured at the levels in the conjoint, so `match` controls how
#' the equal-share price is found:
#'
#' * `"extrapolate"` (the default) solves for the exact price. Each
#'   respondent's price utility is interpolated linearly between the price
#'   levels in the conjoint, which gives a share at any price, and the price
#'   where the shares are equal is found numerically. Outside the lowest and
#'   highest price levels the first or last segment is extended (never below a
#'   price of 0); such rows are flagged in `extrapolated`.
#' * `"closest"` uses the price level whose share is nearest A's.
#' * `"closest_without_going_over"` uses the highest price level at which A'
#'   still has at least A's share. This is a conservative (lower-bound)
#'   estimate, and is `NA` when A' falls short of A even at the lowest price.
#'
#' @section Price reversals:
#' A respondent's price utility should fall as price rises, but individual-level
#' estimates often do not (the utility of $299 can exceed that of $249). Then
#' more than one price can match, and extending the curve beyond the highest
#' price can point the wrong way. With `monotone_price = TRUE` (the default),
#' each such respondent's price utilities are made non-increasing by pooling
#' neighbouring levels that violate the order into their average (pool adjacent
#' violators). Pooling is applied to the reference and every alternative, so a
#' product always matches itself, but `reference_share` can differ slightly from
#' [run_scenario()] when respondents were pooled. A message reports how many
#' were. With `monotone_price = FALSE` utilities are used as they are and the
#' match nearest the reference price is taken.
#'
#' A respondent whose price utility is flat beyond the highest price level has
#' no finite price at which a better alternative matches, so that match is `NA`.
#'
#' @section Individual willingness to pay:
#' With `individual = TRUE` the match is found for each respondent separately.
#' A respondent's choice probability rises with utility, so equal shares means
#' equal utility: NONE and `scaling_factor` drop out, and the result is the price
#' at which that respondent is indifferent between A and A'. Individual values
#' are noisy and can be extreme for respondents who barely respond to price, so
#' summarise them with medians or quantiles rather than means.
#'
#' @inheritParams sensitivity_analysis
#' @param product The reference [product] (A). It must select exactly one level
#'   of the `price` collection.
#' @param alternatives What to compare the reference against. See Details.
#' @param price The name of the price collection. Defaults to `"Price"`.
#' @param price_values Optional named numeric vector giving the numeric value of
#'   each price level, e.g. `c("$199" = 199, "$299" = 299)`. By default the
#'   number is read from the level name (`"$1,299"` becomes 1299), which fails
#'   if a level contains no number or more than one.
#' @param match How to find the price where shares are equal: `"extrapolate"`,
#'   `"closest"`, or `"closest_without_going_over"`. See Matching.
#' @param individual Whether to return one row per respondent and alternative
#'   instead of one row per alternative. Defaults to `FALSE`.
#' @param id With `individual = TRUE`, the name of a column of `x` that
#'   identifies respondents. Its values fill the first column of the result,
#'   which takes its name. Defaults to `NULL`, which numbers respondents by row
#'   in a column called `respondent`.
#' @param monotone_price Whether to make each respondent's price utilities
#'   non-increasing in price before matching. See Price reversals. Defaults to
#'   `TRUE`.
#' @param multiple_select A character vector of collection names that may hold
#'   more than one level at once. Only used when `alternatives` is `NULL`; see
#'   [sensitivity_analysis()].
#'
#' @return A tibble with one row per alternative and the columns:
#'   `alternative` (its name, or a description of what changed),
#'   `reference_price` (A's price), `matched_price` (the price at which A'
#'   matches A), `willingness_to_pay` (`matched_price - reference_price`),
#'   `reference_share` (A's share), `alternative_share` (A''s share at the
#'   matched price), `extrapolated` (whether `matched_price` lies outside the
#'   price levels in the conjoint), and `product_name`. Alternatives that cannot
#'   be matched get `NA` in the price and share columns.
#'
#'   With `individual = TRUE`, one row per respondent and alternative with the
#'   respondent identifier first, then `alternative`, `reference_price`,
#'   `matched_price`, `willingness_to_pay`, `extrapolated`, `price_reversal`
#'   (whether the respondent's price utilities rose with price before any
#'   pooling), and `product_name`. There are no share columns.
#' @examples
#' cjt <- conjoint_df(example_utilities, example_crosswalk)
#' flagship <- product(
#'   cjt,
#'   c("Northwind", "$299", "20 hours", "256 GB", "Black"),
#'   name = "Flagship"
#' )
#'
#' # Every single-level change, one at a time.
#' willingness_to_pay(cjt, flagship)
#'
#' # One upgrade made of several levels.
#' willingness_to_pay(cjt, flagship, alternatives = c("30 hours", "512 GB"))
#'
#' # Several named alternatives, matched to the nearest price level.
#' willingness_to_pay(
#'   cjt,
#'   flagship,
#'   alternatives = list(
#'     Endurance = "30 hours",
#'     Capacity = "512 GB",
#'     Both = c("30 hours", "512 GB")
#'   ),
#'   match = "closest"
#' )
#'
#' # Each respondent's own willingness to pay for the upgrade.
#' upgrade <- willingness_to_pay(
#'   cjt,
#'   flagship,
#'   alternatives = c("30 hours", "512 GB"),
#'   individual = TRUE,
#'   id = "respondent_id"
#' )
#' median(upgrade$willingness_to_pay, na.rm = TRUE)
#' @export
willingness_to_pay <- function(
  x,
  product,
  alternatives = NULL,
  price = "Price",
  price_values = NULL,
  match = c("extrapolate", "closest", "closest_without_going_over"),
  individual = FALSE,
  id = NULL,
  monotone_price = TRUE,
  multiple_select = character(),
  combine_fn = pmax,
  scaling_factor = 1
) {
  match <- rlang::arg_match(match)
  check_bool(individual)
  check_bool(monotone_price)
  collections <- get_collections(x)
  collection_names <- purrr::map_chr(collections, \(cl) cl@name)
  check_multiple_select(multiple_select, collection_names)
  check_products_columns(x, list(product))
  check_combine_fn(combine_fn, x)
  check_price_collection(price, collection_names, product)
  if (individual) {
    check_id(id, x)
  }

  price_levels <- collection_levels(collections[[which(
    collection_names == price
  )]])
  prices <- resolve_price_values(price_levels, price_values)
  ref_col <- which(names(prices) == product@selections[[price]])

  alternatives <- build_alternatives(
    x,
    product,
    alternatives,
    collections,
    multiple_select,
    price
  )

  price_utility <- do.call(cbind, purrr::map(names(prices), \(lv) x[[lv]])) *
    scaling_factor
  reversal <- price_reversals(price_utility)
  if (monotone_price) {
    price_utility <- pool_price_utilities(price_utility, reversal)
    report_reversals(sum(reversal), length(reversal))
  }

  fixed_utility <- function(prod) {
    compute_product_utility(
      x,
      set_selection(prod, price, character()),
      combine_fn
    ) *
      scaling_factor
  }
  fixed_ref <- fixed_utility(product)
  fixed_alts <- purrr::map(alternatives, fixed_utility)

  if (individual) {
    result <- individual_wtp(
      fixed_ref,
      fixed_alts,
      price_utility,
      prices,
      ref_col,
      match,
      respondent = if (is.null(id)) seq_len(nrow(x)) else x[[id]],
      id_name = id %||% "respondent",
      reversal = reversal,
      product_name = product_display_name(product)
    )
    report_individual_matches(result, match, range(prices))
  } else {
    result <- aggregate_wtp(
      fixed_ref,
      fixed_alts,
      price_utility,
      x[[get_none(x)]] * scaling_factor,
      prices,
      ref_col,
      match,
      product_name = product_display_name(product)
    )
    report_matches(result, match, range(prices))
  }
  result
}

# One row per alternative: the price at which its mean share equals A's.
#' @keywords internal
aggregate_wtp <- function(
  fixed_ref,
  fixed_alts,
  price_utility,
  none_utility,
  prices,
  ref_col,
  match,
  product_name
) {
  reference_price <- prices[[ref_col]]
  share_curve <- function(fixed) {
    function(p) {
      u <- fixed + interpolate_utility(price_utility, prices, p)
      mean_shares(matrix(c(u, none_utility), ncol = 2))[[1]]
    }
  }

  reference_share <- share_curve(fixed_ref)(reference_price)
  matches <- purrr::map(fixed_alts, function(fixed) {
    match_price(
      share_curve(fixed),
      reference_share,
      prices,
      reference_price,
      match
    )
  })

  matched_price <- round(unname(purrr::map_dbl(matches, "price")), 2)
  tibble::tibble(
    alternative = names(fixed_alts),
    reference_price = reference_price,
    matched_price = matched_price,
    willingness_to_pay = matched_price - reference_price,
    reference_share = round(reference_share, 3),
    alternative_share = round(unname(purrr::map_dbl(matches, "share")), 3),
    extrapolated = unname(purrr::map_lgl(matches, "extrapolated")),
    product_name = product_name
  )
}

# One row per respondent and alternative. A respondent's choice probability
# rises with utility, so equal shares means equal utility: NONE drops out and
# the match is where A' has the same utility as A for that respondent.
#' @keywords internal
individual_wtp <- function(
  fixed_ref,
  fixed_alts,
  price_utility,
  prices,
  ref_col,
  match,
  respondent,
  id_name,
  reversal,
  product_name
) {
  reference_price <- prices[[ref_col]]
  target <- fixed_ref + price_utility[, ref_col]

  rows <- purrr::imap(fixed_alts, function(fixed, label) {
    matches <- purrr::map(seq_along(target), function(i) {
      row <- price_utility[i, , drop = FALSE]
      curve <- \(p) fixed[[i]] + interpolate_utility(row, prices, p)
      match_price(curve, target[[i]], prices, reference_price, match)
    })
    matched_price <- round(unname(purrr::map_dbl(matches, "price")), 2)
    tibble::tibble(
      respondent = respondent,
      alternative = label,
      reference_price = reference_price,
      matched_price = matched_price,
      willingness_to_pay = matched_price - reference_price,
      extrapolated = unname(purrr::map_lgl(matches, "extrapolated")),
      price_reversal = reversal,
      product_name = product_name
    )
  })
  result <- purrr::list_rbind(unname(rows))
  names(result)[[1]] <- id_name
  result
}

#' @keywords internal
check_bool <- function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (!rlang::is_bool(x)) {
    cli::cli_abort(
      c(
        "x" = "{.arg {arg}} must be {.code TRUE} or {.code FALSE}.",
        "i" = "You supplied {.obj_type_friendly {x}}."
      ),
      call = call
    )
  }
  invisible()
}

#' @keywords internal
check_id <- function(id, x, call = rlang::caller_env()) {
  if (is.null(id)) {
    return(invisible())
  }
  if (!rlang::is_string(id)) {
    cli::cli_abort(
      c(
        "x" = "{.arg id} must be {.code NULL} or a single column name.",
        "i" = "You supplied {.obj_type_friendly {id}}."
      ),
      call = call
    )
  }
  if (!id %in% names(x)) {
    cli::cli_abort(
      c(
        "x" = "{.arg id} must name a column of {.arg x}.",
        "!" = "Not found: {.field {id}}."
      ),
      call = call
    )
  }
  invisible()
}

# Respondents whose utility rises with price anywhere between adjacent levels
# (columns of `utilities`, ordered by price).
#' @keywords internal
price_reversals <- function(utilities) {
  k <- ncol(utilities)
  rowSums(utilities[, -1, drop = FALSE] > utilities[, -k, drop = FALSE]) > 0
}

# Make each reversed respondent's price utilities non-increasing in price by
# pooling violating neighbours into their average (pool adjacent violators).
#' @keywords internal
pool_price_utilities <- function(utilities, reversal) {
  if (any(reversal)) {
    pooled <- apply(utilities[reversal, , drop = FALSE], 1, pool_decreasing)
    utilities[reversal, ] <- t(pooled)
  }
  utilities
}

#' @keywords internal
pool_decreasing <- function(u) {
  means <- numeric()
  sizes <- integer()
  for (value in u) {
    means <- c(means, value)
    sizes <- c(sizes, 1L)
    n <- length(means)
    while (n > 1 && means[[n]] > means[[n - 1]]) {
      size <- sizes[[n]] + sizes[[n - 1]]
      means[[n - 1]] <- (means[[n - 1]] *
        sizes[[n - 1]] +
        means[[n]] * sizes[[n]]) /
        size
      sizes[[n - 1]] <- size
      means <- means[-n]
      sizes <- sizes[-n]
      n <- n - 1
    }
  }
  rep(means, sizes)
}

#' @keywords internal
report_reversals <- function(n_pooled, n) {
  if (n_pooled > 0) {
    cli::cli_inform(c(
      "i" = "Pooled the price utilities of {n_pooled} of {n} respondent{?s} whose utility rose with price.",
      " " = "Set {.code monotone_price = FALSE} to use them as they are."
    ))
  }
  invisible()
}

#' @keywords internal
check_price_collection <- function(
  price,
  collection_names,
  product,
  call = rlang::caller_env()
) {
  if (
    !is.character(price) || length(price) != 1 || !price %in% collection_names
  ) {
    cli::cli_abort(
      c(
        "x" = "{.arg price} must name a single collection of {.arg x}.",
        "i" = "Available collections: {.field {collection_names}}."
      ),
      call = call
    )
  }
  selected <- product@selections[[price]]
  if (length(selected) != 1) {
    cli::cli_abort(
      c(
        "x" = "{.arg product} must select exactly one level of {.field {price}}.",
        "i" = "It selects {length(selected)}."
      ),
      call = call
    )
  }
  invisible()
}

# Numeric price for each level of the price collection, sorted ascending.
#' @keywords internal
resolve_price_values <- function(levels, values, call = rlang::caller_env()) {
  if (is.null(values)) {
    values <- parse_price_levels(levels, call)
  } else {
    check_price_values(values, levels, call)
    values <- values[levels]
  }
  if (length(values) < 2 || anyDuplicated(values) > 0) {
    cli::cli_abort(
      c(
        "x" = "The price collection needs at least two distinct numeric prices.",
        "i" = "Prices found: {.val {unname(values)}}."
      ),
      call = call
    )
  }
  sort(values)
}

#' @keywords internal
parse_price_levels <- function(levels, call) {
  cleaned <- gsub("(?<=[0-9]),(?=[0-9]{3})", "", levels, perl = TRUE)
  numbers <- regmatches(cleaned, gregexpr("[0-9]+(\\.[0-9]+)?", cleaned))
  unreadable <- levels[lengths(numbers) != 1]
  if (length(unreadable) > 0) {
    cli::cli_abort(
      c(
        "x" = "Can't read a price from {cli::qty(unreadable)}level{?s} {.val {unreadable}}.",
        "i" = "Each price level must contain exactly one number, or supply {.arg price_values}."
      ),
      call = call
    )
  }
  stats::setNames(as.numeric(unlist(numbers)), levels)
}

#' @keywords internal
check_price_values <- function(values, levels, call) {
  if (
    !is.numeric(values) || !is_fully_named(values) || !all(is.finite(values))
  ) {
    cli::cli_abort(
      c(
        "x" = "{.arg price_values} must be a named vector of finite numbers.",
        "i" = "You supplied {.obj_type_friendly {values}}."
      ),
      call = call
    )
  }
  missing <- setdiff(levels, names(values))
  unknown <- setdiff(names(values), levels)
  if (length(missing) > 0 || length(unknown) > 0) {
    cli::cli_abort(
      c(
        "x" = "{.arg price_values} must have exactly one value per price level.",
        "!" = if (length(missing) > 0) "Missing: {.val {missing}}.",
        "!" = if (length(unknown) > 0) "Not price levels: {.val {unknown}}.",
        "i" = "Price levels: {.val {levels}}."
      ),
      call = call
    )
  }
  invisible()
}

# Resolve `alternatives` into a named list of products, one per row of output.
#' @keywords internal
build_alternatives <- function(
  x,
  product,
  alternatives,
  collections,
  multiple_select,
  price,
  call = rlang::caller_env()
) {
  if (is.null(alternatives)) {
    grid <- perturbation_grid(
      product,
      collections,
      multiple_select,
      exclude = price
    )
    if (nrow(grid) == 0) {
      cli::cli_abort(
        c(
          "x" = "There is nothing to compare {.arg product} against.",
          "i" = "It has no single-level changes outside {.field {price}}."
        ),
        call = call
      )
    }
    alts <- purrr::map2(grid$Feature, grid$new_levels, function(feature, lv) {
      set_selection(product, feature, lv)
    })
    names(alts) <- purrr::map_chr(alts, \(a) {
      describe_changes(product, a, price)
    })
    return(alts)
  }

  alternatives <- as_alternative_list(alternatives, call)
  # lapply() rather than purrr::map() so errors are not wrapped in "In index: i".
  alts <- lapply(alternatives, function(a) {
    if (is_product(a)) a else swap_in_levels(x, product, a, call)
  })
  check_products_columns(x, alts, call = call)
  same_shape <- purrr::map_lgl(alts, function(a) {
    setequal(names(a@selections), names(product@selections))
  })
  if (!all(same_shape)) {
    cli::cli_abort(
      c(
        "x" = "Every alternative must reference the same collections as {.arg product}."
      ),
      call = call
    )
  }

  given <- names(alternatives) %||% character(length(alts))
  labels <- purrr::map_chr(seq_along(alts), function(i) {
    if (nzchar(given[[i]])) {
      given[[i]]
    } else if (length(alts[[i]]@name) == 1 && nzchar(alts[[i]]@name)) {
      alts[[i]]@name
    } else {
      describe_changes(product, alts[[i]], price)
    }
  })
  names(alts) <- labels

  price_differs <- purrr::map_lgl(alts, function(a) {
    length(a@selections[[price]]) > 0 &&
      !setequal(a@selections[[price]], product@selections[[price]])
  })
  if (any(price_differs)) {
    cli::cli_warn(
      c(
        "!" = "Ignoring the {.field {price}} of {.val {labels[price_differs]}}.",
        "i" = "Price is solved for, so it is not taken from the alternative."
      ),
      call = call
    )
  }
  alts
}

#' @keywords internal
as_alternative_list <- function(alternatives, call) {
  is_alternative <- function(a) is_product(a) || is.character(a)
  if (is_alternative(alternatives)) {
    return(list(alternatives))
  }
  if (
    !is.list(alternatives) ||
      length(alternatives) == 0 ||
      !all(purrr::map_lgl(alternatives, is_alternative))
  ) {
    cli::cli_abort(
      c(
        "x" = "{.arg alternatives} must be {.code NULL}, a {.cls product}, a character vector of levels, or a list of those.",
        "i" = "You supplied {.obj_type_friendly {alternatives}}."
      ),
      call = call
    )
  }
  alternatives
}

# A copy of `product` with every collection touched by `levels` replaced.
#' @keywords internal
swap_in_levels <- function(x, product, levels, call) {
  chosen <- group_levels(x, levels, call = call, warn_empty = FALSE)
  chosen <- purrr::keep(chosen, \(lv) length(lv) > 0)
  selections <- product@selections
  selections[names(chosen)] <- chosen
  S7::set_props(product, name = character(), selections = selections)
}

# "Battery: 20 hours -> 30 hours; Storage: ..." for every collection (other than
# `exclude`) whose selection differs between the two products.
#' @keywords internal
describe_changes <- function(product, alt, exclude) {
  collapse <- function(levels) {
    if (length(levels) == 0) "(none)" else paste(levels, collapse = " + ")
  }
  collections <- setdiff(names(product@selections), exclude)
  changed <- purrr::discard(collections, function(cl) {
    setequal(product@selections[[cl]], alt@selections[[cl]])
  })
  if (length(changed) == 0) {
    return("(no change)")
  }
  paste(
    purrr::map_chr(changed, function(cl) {
      paste0(
        cl,
        ": ",
        collapse(product@selections[[cl]]),
        " \u2192 ",
        collapse(alt@selections[[cl]])
      )
    }),
    collapse = "; "
  )
}

# Each respondent's price utility at price `p`, interpolated linearly between
# the prices in the conjoint (columns of `utilities`, ordered like `prices`) and extended
# along the first or last segment outside them.
#' @keywords internal
interpolate_utility <- function(utilities, prices, p) {
  i <- min(max(findInterval(p, prices), 1L), length(prices) - 1L)
  weight <- (p - prices[[i]]) / (prices[[i + 1]] - prices[[i]])
  utilities[, i] + weight * (utilities[, i + 1] - utilities[, i])
}

# The price at which `curve` (price -> share) reaches `target`, with the share
# there. `price` is NA when no price can be found.
#' @keywords internal
match_price <- function(curve, target, prices, reference_price, match) {
  gap <- unname(purrr::map_dbl(prices, curve)) - target
  price <- switch(
    match,
    extrapolate = solve_price(curve, target, prices, gap, reference_price),
    closest = prices[[which.min(abs(gap))]],
    closest_without_going_over = {
      under <- which(gap >= -1e-9)
      if (length(under) == 0) NA_real_ else max(prices[under])
    }
  )
  if (is.na(price)) {
    return(list(price = NA_real_, share = NA_real_, extrapolated = NA))
  }
  list(
    price = price,
    share = curve(price),
    extrapolated = price < min(prices) || price > max(prices)
  )
}

# Solve curve(p) == target. Inside the conjoint's price range the crossing
# nearest the reference price wins (a flat stretch at the target counts as the
# reference price itself); otherwise the search continues beyond the nearer end.
#' @keywords internal
solve_price <- function(curve, target, prices, gap, reference_price) {
  f <- \(p) curve(p) - target
  root <- \(lower, upper) {
    stats::uniroot(f, c(lower, upper), tol = 1e-8)$root
  }
  k <- length(prices)

  crossing <- which(gap[-k] * gap[-1] <= 0)
  if (length(crossing) > 0) {
    roots <- purrr::map_dbl(crossing, function(i) {
      if (gap[[i]] == 0 && gap[[i + 1]] == 0) {
        return(min(max(reference_price, prices[[i]]), prices[[i + 1]]))
      }
      root(prices[[i]], prices[[i + 1]])
    })
    return(roots[[which.min(abs(roots - reference_price))]])
  }

  if (all(gap > 0)) {
    span <- prices[[k]] - prices[[1]]
    lower <- prices[[k]]
    for (step in span * 2^(0:20)) {
      upper <- prices[[k]] + step
      if (f(upper) <= 0) {
        return(root(lower, upper))
      }
      lower <- upper
    }
    return(NA_real_)
  }

  if (f(0) < 0) NA_real_ else root(0, prices[[1]])
}

#' @keywords internal
unmatched_hint <- function(match) {
  if (match == "extrapolate") {
    "The shares never meet at a price of 0 or more."
  } else {
    "The alternative trails the reference even at the lowest price level."
  }
}

#' @keywords internal
report_matches <- function(result, match, price_range) {
  unmatched <- result$alternative[is.na(result$matched_price)]
  if (length(unmatched) > 0) {
    cli::cli_warn(
      c(
        "!" = "No matching price for {cli::qty(unmatched)}alternative{?s} {.val {unmatched}}.",
        "i" = unmatched_hint(match)
      ),
      call = rlang::caller_env()
    )
  }

  extrapolated <- result$alternative[result$extrapolated %in% TRUE]
  if (length(extrapolated) > 0) {
    cli::cli_inform(c(
      "i" = "Extrapolated beyond the price range of the conjoint ({.val {price_range[[1]]}} to {.val {price_range[[2]]}}) for {.val {extrapolated}}."
    ))
  }

  if (match != "extrapolate") {
    at_edge <- result$alternative[
      (result$matched_price == price_range[[2]] &
        result$alternative_share > result$reference_share) |
        (result$matched_price == price_range[[1]] &
          result$alternative_share < result$reference_share)
    ]
    at_edge <- at_edge[!is.na(at_edge)]
    if (length(at_edge) > 0) {
      cli::cli_inform(c(
        "i" = "{.val {at_edge}} still differ{?s/} from the reference at the edge of the conjoint's price range, so the true match lies beyond it.",
        "i" = "Use {.code match = \"extrapolate\"} to estimate it."
      ))
    }
  }
  invisible(result)
}

#' @keywords internal
report_individual_matches <- function(result, match, price_range) {
  total <- nrow(result)
  unmatched <- sum(is.na(result$matched_price))
  if (unmatched > 0) {
    cli::cli_warn(
      c(
        "!" = "No matching price for {unmatched} of {total} respondent-alternative pair{?s}.",
        "i" = unmatched_hint(match)
      ),
      call = rlang::caller_env()
    )
  }

  extrapolated <- sum(result$extrapolated %in% TRUE)
  if (extrapolated > 0) {
    cli::cli_inform(c(
      "i" = "{extrapolated} of {total} respondent-alternative pair{?s} extrapolated beyond the price range of the conjoint ({.val {price_range[[1]]}} to {.val {price_range[[2]]}})."
    ))
  }
  invisible(result)
}
