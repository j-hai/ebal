# =============================================================================
# S3 methods for ebalance and ebalance.trim objects.
#
# All purely additive — old code that reads list fields by name continues
# to work; these methods just provide nicer defaults for print/summary/plot
# and a length-n weights() vector that's drop-in for lm()/svyglm().
# =============================================================================

# ---- internal helpers -------------------------------------------------------

# Build a balance table comparing pre- and post-weighting moments
# under a binary Treatment vector and a length-n weights_full vector.
# Treatment-side and control-side post-weighting means are computed
# from whichever side carries non-trivial weights — for ATT only the
# control side moves; for ATC only the treated side moves; for ATE
# both move and the post-weighting columns are the weighted means of
# each group separately.
.balance_table <- function(Treatment, X, weights_full) {
  is.t <- Treatment == 1
  is.c <- Treatment == 0
  Xt <- X[is.t, , drop = FALSE]
  Xc <- X[is.c, , drop = FALSE]
  wt <- weights_full[is.t]
  wc <- weights_full[is.c]

  mean.t.pre  <- colMeans(Xt)
  mean.c.pre  <- colMeans(Xc)
  mean.t.post <- if (sum(wt) > 0) apply(Xt, 2, weighted.mean, w = wt) else mean.t.pre
  mean.c.post <- if (sum(wc) > 0) apply(Xc, 2, weighted.mean, w = wc) else mean.c.pre

  var.t  <- apply(Xt, 2, var)
  var.c  <- apply(Xc, 2, var)
  sd.pool <- sqrt((var.t + var.c) / 2)
  sd.pool[sd.pool == 0] <- NA_real_

  data.frame(
    mean.Tr        = mean.t.post,
    mean.Co.pre    = mean.c.pre,
    mean.Co.post   = mean.c.post,
    diff.pre       = mean.t.pre  - mean.c.pre,
    diff.post      = mean.t.post - mean.c.post,
    std.diff.pre   = (mean.t.pre  - mean.c.pre)  / sd.pool,
    std.diff.post  = (mean.t.post - mean.c.post) / sd.pool,
    row.names = colnames(X),
    stringsAsFactors = FALSE
  )
}

# ---- print methods ----------------------------------------------------------

print.ebalance <- function(x, ...) {
  estimand <- x$estimand %||% "ATT"
  cat("Entropy balancing  (estimand: ", estimand, ")\n", sep = "")
  cat("---------------------------------\n")
  ntreated  <- if (!is.null(x$Treatment)) sum(x$Treatment == 1) else NA
  ncontrols <- if (!is.null(x$Treatment)) sum(x$Treatment == 0) else NA
  if (estimand == "ATT") {
    cat(sprintf("Treated:    %d\n", ntreated))
    cat(sprintf("Controls:   %d (reweighted; sum of weights = %.3f)\n",
                ncontrols, sum(x$w)))
  } else if (estimand == "ATC") {
    cat(sprintf("Treated:    %d (reweighted; sum of weights = %.3f)\n",
                ntreated, sum(x$w)))
    cat(sprintf("Controls:   %d\n", ncontrols))
  } else {
    cat(sprintf("Treated:    %d (reweighted; sum of weights = %.3f)\n",
                ntreated, sum(x$treated_solve$w)))
    cat(sprintf("Controls:   %d (reweighted; sum of weights = %.3f)\n",
                ncontrols, sum(x$control_solve$w)))
  }
  nmom <- length(x$target.margins) - 1L  # subtract the norm.constant entry
  cat(sprintf("Moments:    %d covariate moment(s) balanced\n", nmom))
  if (estimand == "ATE") {
    cat(sprintf("Converged:  control = %s, treated = %s   (max deviation = %.3g)\n",
                x$control_solve$converged, x$treated_solve$converged, x$maxdiff))
  } else {
    cat(sprintf("Converged:  %s   (max moment deviation = %.3g)\n",
                x$converged, x$maxdiff))
  }
  cat("\nUse summary() for a balance table, weights() for the per-unit\n")
  cat("weight vector, and plot() for a Love plot of standardized differences.\n")
  invisible(x)
}

print.ebalance.trim <- function(x, ...) {
  cat("Entropy balancing (trimmed weights)\n")
  cat("-----------------------------------\n")
  ntreated  <- if (!is.null(x$Treatment)) sum(x$Treatment == 1) else NA
  ncontrols <- length(x$w)
  cat(sprintf("Treated:        %d\n", ntreated))
  cat(sprintf("Controls:       %d (sum of weights = %.3f)\n",
              ncontrols, sum(x$w)))
  nmom <- length(x$target.margins) - 1L
  cat(sprintf("Moments:        %d covariate moment(s) balanced\n", nmom))
  cat(sprintf("Converged:      %s   (max moment deviation = %.3g)\n",
              x$converged, x$maxdiff))
  cat(sprintf("Trim feasible:  %s   (max weight ratio = %.3f)\n",
              x$trim.feasible, max(x$w) / mean(x$w)))
  if (isFALSE(x$trim.feasible)) {
    cat("\n  ! requested max.weight target was not achieved;\n",
        "  ! the most recent feasible fit is returned.\n", sep = "")
  }
  invisible(x)
}

# ---- summary methods --------------------------------------------------------

summary.ebalance <- function(object, ...) {
  if (is.null(object$Treatment) || is.null(object$X)) {
    stop("This ebalance object was fit before Treatment/X were stored ",
         "in the result; refit with the current package version to use ",
         "summary().")
  }
  bal <- .balance_table(object$Treatment, object$X, weights(object))
  out <- list(
    call.info = list(n.treated  = sum(object$Treatment == 1),
                     n.controls = sum(object$Treatment == 0),
                     converged  = object$converged,
                     maxdiff    = object$maxdiff),
    balance   = bal
  )
  class(out) <- "summary.ebalance"
  out
}

summary.ebalance.trim <- function(object, ...) {
  if (is.null(object$Treatment) || is.null(object$X)) {
    stop("This ebalance.trim object was fit before Treatment/X were stored ",
         "in the result; refit with the current package version to use ",
         "summary().")
  }
  bal <- .balance_table(object$Treatment, object$X, weights(object))
  out <- list(
    call.info = list(n.treated      = sum(object$Treatment == 1),
                     n.controls     = sum(object$Treatment == 0),
                     converged      = object$converged,
                     maxdiff        = object$maxdiff,
                     trim.feasible  = object$trim.feasible,
                     max.weight.ratio = max(object$w) / mean(object$w)),
    balance   = bal
  )
  class(out) <- "summary.ebalance.trim"
  out
}

print.summary.ebalance <- function(x, digits = 4, ...) {
  ci <- x$call.info
  cat("Entropy balancing summary\n")
  cat(sprintf("  Treated:   %d   Controls: %d   Converged: %s   max moment deviation: %.3g\n",
              ci$n.treated, ci$n.controls, ci$converged, ci$maxdiff))
  cat("\nBalance table (means and standardized differences):\n\n")
  print(round(x$balance, digits = digits))
  invisible(x)
}

print.summary.ebalance.trim <- function(x, digits = 4, ...) {
  ci <- x$call.info
  cat("Entropy balancing (trimmed) summary\n")
  cat(sprintf("  Treated: %d   Controls: %d   Converged: %s   max moment deviation: %.3g\n",
              ci$n.treated, ci$n.controls, ci$converged, ci$maxdiff))
  cat(sprintf("  Trim feasible: %s   max weight ratio: %.3f\n",
              ci$trim.feasible, ci$max.weight.ratio))
  cat("\nBalance table (means and standardized differences):\n\n")
  print(round(x$balance, digits = digits))
  invisible(x)
}

# ---- weights methods --------------------------------------------------------
#
# Returns a length-n vector aligned to the original Treatment/X. Treated
# units receive weight 1; control units receive their entropy-balancing
# weight. Suitable for passing directly to lm(..., weights = w),
# svyglm(...), etc.

weights.ebalance <- function(object, ...) {
  if (is.null(object$Treatment)) {
    stop("This ebalance object has no Treatment field; refit with the ",
         "current package version to use weights() at full length, or ",
         "read object$w for the controls-only vector.")
  }
  estimand <- object$estimand %||% "ATT"
  out <- numeric(length(object$Treatment))
  if (estimand == "ATT") {
    # Controls reweighted; treated units carry weight 1.
    out[object$Treatment == 1] <- 1
    out[object$Treatment == 0] <- object$w
  } else if (estimand == "ATC") {
    # Treated reweighted; control units carry weight 1.
    out[object$Treatment == 1] <- object$w
    out[object$Treatment == 0] <- 1
  } else {
    # ATE: both groups carry estimated weights from their respective solves.
    out[object$Treatment == 0] <- object$control_solve$w
    out[object$Treatment == 1] <- object$treated_solve$w
  }
  out
}

weights.ebalance.trim <- function(object, ...) {
  if (is.null(object$Treatment)) {
    stop("This ebalance.trim object has no Treatment field; refit with ",
         "the current package version to use weights() at full length, or ",
         "read object$w for the controls-only vector.")
  }
  out <- numeric(length(object$Treatment))
  out[object$Treatment == 1] <- 1
  out[object$Treatment == 0] <- object$w
  out
}

# ---- plot methods -----------------------------------------------------------
#
# Love plot: absolute standardized differences pre- and post-weighting,
# one row per covariate. Base graphics, no ggplot2 dependency.

plot.ebalance <- function(x,
                          abs.values = TRUE,
                          xlab = NULL,
                          main = NULL,
                          ...) {
  if (is.null(xlab)) {
    xlab <- if (abs.values) "Absolute standardized difference"
            else "Standardized difference"
  }
  if (is.null(main)) {
    main <- "Covariate balance (before vs. after entropy balancing)"
  }
  if (is.null(x$Treatment) || is.null(x$X)) {
    stop("plot() requires the Treatment and X fields, which are stored ",
         "by the current package version. Refit to use plot().")
  }
  bal <- .balance_table(x$Treatment, x$X, weights(x))
  pre  <- bal$std.diff.pre
  post <- bal$std.diff.post
  if (abs.values) { pre <- abs(pre); post <- abs(post) }
  k <- nrow(bal)
  ord <- order(abs(bal$std.diff.pre), decreasing = FALSE)
  ylim <- c(1, k)
  xlim <- range(c(0, pre, post), na.rm = TRUE)
  if (abs.values) xlim[1] <- 0

  op <- par(mar = c(4, max(8, max(nchar(rownames(bal))) * 0.6), 3, 1))
  on.exit(par(op), add = TRUE)
  plot(pre[ord], seq_len(k), type = "n",
       xlim = xlim, ylim = ylim,
       xlab = xlab, ylab = "", yaxt = "n", main = main, ...)
  axis(2, at = seq_len(k), labels = rownames(bal)[ord], las = 1)
  if (abs.values) abline(v = 0, col = "grey80")
  else            abline(v = 0, col = "grey80")
  points(pre[ord],  seq_len(k), pch = 1, col = "black")
  points(post[ord], seq_len(k), pch = 19, col = "darkblue")
  legend("topright",
         legend = c("before", "after"),
         pch = c(1, 19), col = c("black", "darkblue"),
         bty = "n", inset = 0.02)
  invisible(bal)
}

plot.ebalance.trim <- function(x, ...) plot.ebalance(x, ...)
