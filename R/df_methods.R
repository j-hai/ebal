# as.data.frame.ebalance — return the balance table in tidy long form.
# Defers to .balance_table() in methods.R for the underlying computation
# so the column conventions stay consistent with summary.ebalance().

as.data.frame.ebalance <-
function(x, ...)
  {
    if (is.null(x$Treatment) || is.null(x$X))
      stop("\n as.data.frame() requires the Treatment vector and X matrix on\n the ebalance object (added in 0.2.0). Refit with the current\n ebalance() to enable this method. \n")
    bt <- .balance_table(x$Treatment, x$X, x$w)
    data.frame(
      term            = rownames(bt),
      mean_treated    = bt$mean.Tr,
      mean_control    = bt$mean.Co.pre,
      mean_control_w  = bt$mean.Co.post,
      diff_pre        = bt$diff.pre,
      diff_post       = bt$diff.post,
      std_diff_pre    = bt$std.diff.pre,
      std_diff_post   = bt$std.diff.post,
      stringsAsFactors = FALSE,
      row.names = NULL
    )
  }

as.data.frame.ebalance.trim <- as.data.frame.ebalance
