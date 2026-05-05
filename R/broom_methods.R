# tidy() / glance() / augment() methods for ebalance and ebalance.trim
# objects. Registered against the generics in the `generics` package
# (which is what `broom` re-exports). Discoverable via library(broom).

tidy.ebalance <-
function(x, ...)
  {
    if (is.null(x$Treatment) || is.null(x$X))
      stop("\n tidy() requires the Treatment vector and X matrix to be\n stored on the ebalance object (added in 0.2.0). Refit with the\n current ebalance() to enable this method. \n")
    # Route through the canonical balance_table() so the per-side
    # pre/post columns stay consistent for ATC and ATE (where the
    # treated-side mean changes between pre- and post-weighting).
    bt <- balance_table(x)
    # Rename `variable` -> `term` for broom-style ergonomics; otherwise
    # the column shape is identical.
    names(bt)[names(bt) == "variable"] <- "term"
    bt
  }

tidy.ebalance.trim <- tidy.ebalance

glance.ebalance <-
function(x, ...)
  {
    ag <- .active_group(x)
    nmom <- length(x$target.margins) - 1L
    # Per-side ESS / max-weight diagnostics: each is computed against
    # the relevant side's weight vector (treated for ATC, control for
    # ATT; both for ATE). For sides that aren't reweighted the
    # diagnostic falls back to the trivial values (ESS = n, max = 1,
    # ratio = 1) so the column shape is uniform across estimands.
    .ess <- function(w) if (sum(w) > 0) sum(w)^2 / sum(w^2) else NA_real_
    .ratio <- function(w) if (length(w) > 0) max(w) / mean(w) else NA_real_

    # Standardized-difference summaries via balance_table().
    bt <- balance_table(x)
    max_pre  <- max(abs(bt$std_diff_pre),  na.rm = TRUE)
    max_post <- max(abs(bt$std_diff_post), na.rm = TRUE)

    data.frame(
      estimand                  = ag$estimand,
      n_treated                 = length(ag$it),
      n_control                 = length(ag$ic),
      n_moments                 = nmom,
      sum_weights_control       = sum(ag$w_control),
      sum_weights_treated       = sum(ag$w_treated),
      ess_control               = .ess(ag$w_control),
      ess_treated               = .ess(ag$w_treated),
      max_weight_control        = max(ag$w_control),
      max_weight_treated        = max(ag$w_treated),
      max_weight_ratio_control  = .ratio(ag$w_control),
      max_weight_ratio_treated  = .ratio(ag$w_treated),
      max_abs_std_diff_pre      = max_pre,
      max_abs_std_diff_post     = max_post,
      maxdiff                   = x$maxdiff,
      converged                 = x$converged,
      stringsAsFactors          = FALSE
    )
  }

glance.ebalance.trim <-
function(x, ...)
  {
    out <- glance.ebalance(x)
    out$trim_feasible <- x$trim.feasible
    out
  }

augment.ebalance <-
function(x, data = NULL, ...)
  {
    if (is.null(x$Treatment))
      stop("\n augment() requires the Treatment vector on the ebalance object \n")
    w <- weights(x)  # length-n: treated = 1, controls = x$w
    if (is.null(data)) {
      out <- data.frame(.weight = w)
      if (!is.null(x$X)) {
        Xdf <- as.data.frame(x$X)
        out <- cbind(.weight = w, .treatment = as.integer(x$Treatment), Xdf)
      }
      return(out)
    }
    if (NROW(data) != length(w))
      stop(sprintf(
        "\n augment(): supplied data has %d rows but the fit was built on %d \n",
        NROW(data), length(w)))
    out <- data.frame(data, stringsAsFactors = FALSE)
    out$.weight <- w
    out
  }

augment.ebalance.trim <- augment.ebalance
