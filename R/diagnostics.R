# diagnostics(fit): "is my fit okay?" — the friendlier counterpart to
# glance(fit). Returns the same one-row data.frame as glance() plus a
# trim_feasible column, with extra structure on the print() side
# rendering each diagnostic as PASS / WARN / FAIL relative to the
# package's recommended thresholds.

diagnostics <-
function(fit,
         ess_warn   = 0.30,   # warn if ESS / n on the reweighted side < this fraction
         ratio_warn = 10,     # warn if max-weight ratio > this on the reweighted side
         std_diff_warn = 0.05 # warn if max post-weighting |std diff| > this
        )
  {
    if (!inherits(fit, c("ebalance", "ebalance.trim")))
      stop("diagnostics() requires an ebalance or ebalance.trim object")
    .check_threshold <- function(x, label, lo = 0, hi = Inf) {
      if (length(x) != 1 || !is.numeric(x) || !is.finite(x) || x < lo || x > hi)
        stop(sprintf("%s must be a finite scalar in [%g, %s]",
                     label, lo, if (is.finite(hi)) format(hi) else "Inf"))
    }
    .check_threshold(ess_warn,      "ess_warn",      0, 1)
    .check_threshold(ratio_warn,    "ratio_warn",    1, Inf)
    .check_threshold(std_diff_warn, "std_diff_warn", 0, Inf)

    # Reuse glance.ebalance() for the bulk of the numbers.
    g <- glance.ebalance(fit)
    g$trim_feasible <- if (inherits(fit, "ebalance.trim")) fit$trim.feasible
                       else NA

    out <- as.list(g)
    out$thresholds <- list(
      ess_warn      = ess_warn,
      ratio_warn    = ratio_warn,
      std_diff_warn = std_diff_warn
    )

    # Build per-check status flags. PASS / WARN / FAIL with a short note.
    .ratio_check <- function(side_n, side_ess, side_ratio) {
      if (side_n == 0)               return(list(status = "PASS", msg = "(no units on this side)"))
      if (!isTRUE(side_ess >= 0))    return(list(status = "FAIL", msg = "(non-finite ESS)"))
      ess_frac <- side_ess / side_n
      if (ess_frac < ess_warn)
        return(list(status = "WARN",
                    msg = sprintf("ESS = %.0f / %d (%.0f%%); below %.0f%% threshold",
                                  side_ess, side_n, 100 * ess_frac, 100 * ess_warn)))
      if (side_ratio > ratio_warn)
        return(list(status = "WARN",
                    msg = sprintf("max/mean weight ratio = %.2f; above %.2f threshold",
                                  side_ratio, ratio_warn)))
      list(status = "PASS",
           msg = sprintf("ESS = %.0f / %d, max/mean = %.2f",
                         side_ess, side_n, side_ratio))
    }

    out$check_control <- .ratio_check(g$n_control, g$ess_control,
                                      g$max_weight_ratio_control)
    out$check_treated <- .ratio_check(g$n_treated, g$ess_treated,
                                      g$max_weight_ratio_treated)

    out$check_balance <-
      if (is.na(g$max_abs_std_diff_post)) {
        list(status = "FAIL", msg = "balance not computable")
      } else if (g$max_abs_std_diff_post > std_diff_warn) {
        list(status = "WARN",
             msg = sprintf("max |std diff post| = %.4f; above %.2f threshold",
                           g$max_abs_std_diff_post, std_diff_warn))
      } else {
        list(status = "PASS",
             msg = sprintf("max |std diff post| = %.4f", g$max_abs_std_diff_post))
      }

    out$check_converged <-
      if (isTRUE(g$converged))
        list(status = "PASS", msg = sprintf("max moment deviation = %.3g", g$maxdiff))
      else
        list(status = "FAIL", msg = sprintf("did not converge (max moment deviation = %.3g)",
                                            g$maxdiff))

    if (!is.na(out$trim_feasible)) {
      out$check_trim <-
        if (isTRUE(out$trim_feasible))
          list(status = "PASS", msg = "requested max.weight target met")
        else
          list(status = "WARN", msg = "requested max.weight target not met; most-recent feasible fit returned")
    }

    class(out) <- "ebalance.diagnostics"
    out
  }

print.ebalance.diagnostics <-
function(x, ...)
  {
    cat("ebalance diagnostics  (estimand: ", x$estimand, ")\n", sep = "")
    cat("--------------------------------------\n")
    fmt <- function(label, chk) {
      tag <- switch(chk$status,
                    PASS = "PASS",
                    WARN = "WARN",
                    FAIL = "FAIL",
                    chk$status)
      cat(sprintf("  %-12s %-4s  %s\n", label, tag, chk$msg))
    }
    if (x$n_control > 0) fmt("control", x$check_control)
    if (x$n_treated > 0) fmt("treated", x$check_treated)
    fmt("balance",  x$check_balance)
    fmt("converged", x$check_converged)
    if (!is.null(x$check_trim)) fmt("trim", x$check_trim)
    cat("\nThresholds: ESS >= ", round(100 * x$thresholds$ess_warn), "% of n, ",
        "max/mean weight ratio <= ", x$thresholds$ratio_warn, ", ",
        "max |std diff post| <= ", x$thresholds$std_diff_warn, ".\n", sep = "")
    cat("Override via diagnostics(fit, ess_warn = ..., ratio_warn = ..., std_diff_warn = ...).\n")
    invisible(x)
  }
