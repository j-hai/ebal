# Exported user-facing balance table.
#
# Returns a per-covariate data frame comparing pre- and post-weighting
# moments under the estimand the fit was built for. Columns:
#
#   variable           covariate name (rownames(X))
#   mean_treated_pre   raw treated mean
#   mean_treated_post  weighted treated mean (= mean_treated_pre for ATT)
#   mean_control_pre   raw control mean
#   mean_control_post  weighted control mean (= mean_control_pre for ATC)
#   diff_pre           treated_pre  - control_pre
#   diff_post          treated_post - control_post
#   std_diff_pre       diff_pre  / pooled SD (pre-weighting)
#   std_diff_post      diff_post / pooled SD (pre-weighting; same denominator)
#   pct_reduction      100 * (1 - |std_diff_post| / |std_diff_pre|)
#                      ; NA when std_diff_pre is zero
#
# This is the canonical balance representation for the package. The
# tidy(), summary(), as.data.frame(), plot(), and autoplot() methods
# all consume it (or its internal counterpart .balance_table()).

balance_table <- function(fit) {
  if (!inherits(fit, c("ebalance", "ebalance.trim")))
    stop("balance_table() requires an ebalance or ebalance.trim object")
  if (is.null(fit$Treatment) || is.null(fit$X))
    stop("\n balance_table() requires the Treatment vector and X matrix on\n the ebalance object (added in 0.2.0). Refit with the current\n ebalance() to enable this method. \n")
  ag <- .active_group(fit)
  bt <- .balance_table(fit$Treatment, fit$X, ag$w_full)
  pct <- ifelse(is.na(bt$std.diff.pre) | bt$std.diff.pre == 0,
                NA_real_,
                100 * (1 - abs(bt$std.diff.post) / abs(bt$std.diff.pre)))
  out <- data.frame(
    variable          = rownames(bt),
    mean_treated_pre  = colMeans(fit$X[fit$Treatment == 1, , drop = FALSE]),
    mean_treated_post = bt$mean.Tr,
    mean_control_pre  = bt$mean.Co.pre,
    mean_control_post = bt$mean.Co.post,
    diff_pre          = bt$diff.pre,
    diff_post         = bt$diff.post,
    std_diff_pre      = bt$std.diff.pre,
    std_diff_post     = bt$std.diff.post,
    pct_reduction     = pct,
    stringsAsFactors  = FALSE,
    row.names         = NULL
  )
  attr(out, "estimand") <- ag$estimand
  out
}
