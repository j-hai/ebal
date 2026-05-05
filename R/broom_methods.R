# tidy() / glance() / augment() methods for ebalance and ebalance.trim
# objects. Registered against the generics in the `generics` package
# (which is what `broom` re-exports). Discoverable via library(broom).

tidy.ebalance <-
function(x, ...)
  {
    if (is.null(x$Treatment) || is.null(x$X))
      stop("\n tidy() requires the Treatment vector and X matrix to be\n stored on the ebalance object (added in 0.2.0). Refit with the\n current ebalance() to enable this method. \n")
    bt <- .balance_table(x$Treatment, x$X, x$w)
    out <- data.frame(
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
    out
  }

tidy.ebalance.trim <- tidy.ebalance

glance.ebalance <-
function(x, ...)
  {
    n_treated  <- if (!is.null(x$Treatment)) sum(x$Treatment == 1) else NA_integer_
    n_control  <- length(x$w)
    nmom       <- length(x$target.margins) - 1L
    sum_w      <- sum(x$w)
    # Effective sample size (Kish): (sum w)^2 / sum(w^2)
    ess <- if (sum_w > 0) sum_w^2 / sum(x$w^2) else NA_real_
    data.frame(
      n_treated      = n_treated,
      n_control      = n_control,
      n_moments      = nmom,
      sum_weights    = sum_w,
      ess_kish       = ess,
      max_weight     = max(x$w),
      max_weight_ratio = max(x$w) / mean(x$w),
      maxdiff        = x$maxdiff,
      converged      = x$converged,
      stringsAsFactors = FALSE
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
