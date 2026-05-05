# as.data.frame.ebalance — return the balance table in tidy form.
# Defers to balance_table() so summary / tidy / as.data.frame all share
# the same per-estimand column semantics (treated pre/post and control
# pre/post both explicit; diff_pre and diff_post computed consistently).

as.data.frame.ebalance <-
function(x, ...)
  {
    if (is.null(x$Treatment) || is.null(x$X))
      stop("\n as.data.frame() requires the Treatment vector and X matrix on\n the ebalance object (added in 0.2.0). Refit with the current\n ebalance() to enable this method. \n")
    balance_table(x)
  }

as.data.frame.ebalance.trim <- as.data.frame.ebalance
