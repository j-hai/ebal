# =============================================================================
# S3 methods for ebalance and ebalance.trim objects.
#
# All purely additive — old code that reads list fields by name continues
# to work; these methods just provide nicer defaults for print/summary/plot
# and a length-n weights() vector that's drop-in for lm()/svyglm().
# =============================================================================

# ---- internal helpers -------------------------------------------------------

# Resolve which side(s) of the panel carry the estimated weights for a
# given ebalance fit. Returns a list with:
#   $estimand        -- character: "ATT" / "ATC" / "ATE"
#   $reweighted      -- character: "controls" / "treated" / "both"
#   $w_treated       -- length-n_treated vector of fitted weights for the
#                       treated side (rep(1, n_treated) when treated is the
#                       reference side -- i.e. ATT)
#   $w_control       -- analogous for the control side
#   $w_full          -- length-n vector aligned to fit$Treatment
# All print/summary/plot/balance/glance methods call this once at the top
# instead of re-implementing the estimand branch each time.
.active_group <- function(fit) {
  estimand <- fit$estimand %||% "ATT"
  Treatment <- fit$Treatment
  if (is.null(Treatment))
    stop("ebalance fit has no Treatment field; refit with the current package version")
  n  <- length(Treatment)
  it <- which(Treatment == 1)
  ic <- which(Treatment == 0)
  if (estimand == "ATT") {
    w_treated <- rep(1, length(it))
    w_control <- fit$w
    reweighted <- "controls"
  } else if (estimand == "ATC") {
    w_treated <- fit$w
    w_control <- rep(1, length(ic))
    reweighted <- "treated"
  } else {
    w_treated <- fit$treated_solve$w
    w_control <- fit$control_solve$w
    reweighted <- "both"
  }
  w_full <- numeric(n)
  w_full[it] <- w_treated
  w_full[ic] <- w_control
  list(estimand   = estimand,
       reweighted = reweighted,
       w_treated  = w_treated,
       w_control  = w_control,
       w_full     = w_full,
       it         = it,
       ic         = ic)
}

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
  ag <- .active_group(x)
  cat("Entropy balancing  (estimand: ", ag$estimand, ")\n", sep = "")
  cat("---------------------------------\n")
  reweighted_t <- ag$reweighted %in% c("treated", "both")
  reweighted_c <- ag$reweighted %in% c("controls", "both")
  cat(sprintf("Treated:    %d%s\n", length(ag$it),
              if (reweighted_t)
                sprintf(" (reweighted; sum of weights = %.3f)", sum(ag$w_treated))
              else ""))
  cat(sprintf("Controls:   %d%s\n", length(ag$ic),
              if (reweighted_c)
                sprintf(" (reweighted; sum of weights = %.3f)", sum(ag$w_control))
              else ""))
  nmom <- length(x$target.margins) - 1L
  cat(sprintf("Moments:    %d covariate moment(s) balanced\n", nmom))
  if (ag$estimand == "ATE") {
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
  ag <- .active_group(x)
  cat("Entropy balancing (trimmed weights, estimand: ", ag$estimand, ")\n", sep = "")
  cat("---------------------------------------------\n")
  reweighted_t <- ag$reweighted %in% c("treated", "both")
  reweighted_c <- ag$reweighted %in% c("controls", "both")
  cat(sprintf("Treated:        %d%s\n", length(ag$it),
              if (reweighted_t)
                sprintf(" (reweighted; sum of weights = %.3f)", sum(ag$w_treated))
              else ""))
  cat(sprintf("Controls:       %d%s\n", length(ag$ic),
              if (reweighted_c)
                sprintf(" (reweighted; sum of weights = %.3f)", sum(ag$w_control))
              else ""))
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
  bal <- balance_table(object)
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
  bal <- balance_table(object)
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

.print_balance_df <- function(bal, digits) {
  # balance_table() returns a data frame with a character `variable`
  # column; move it to row.names before rounding the numeric columns
  # so print() lays out cleanly.
  rn  <- bal$variable
  num <- bal[, setdiff(names(bal), "variable"), drop = FALSE]
  num <- as.data.frame(lapply(num, function(col)
    if (is.numeric(col)) round(col, digits = digits) else col))
  rownames(num) <- rn
  print(num)
}

print.summary.ebalance <- function(x, digits = 4, ...) {
  ci <- x$call.info
  cat("Entropy balancing summary\n")
  cat(sprintf("  Treated:   %d   Controls: %d   Converged: %s   max moment deviation: %.3g\n",
              ci$n.treated, ci$n.controls, ci$converged, ci$maxdiff))
  cat("\nBalance table (means and standardized differences):\n\n")
  .print_balance_df(x$balance, digits)
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
  .print_balance_df(x$balance, digits)
  invisible(x)
}

# ---- weights methods --------------------------------------------------------
#
# Returns a length-n vector aligned to the original Treatment/X. Treated
# units receive weight 1; control units receive their entropy-balancing
# weight. Suitable for passing directly to lm(..., weights = w),
# svyglm(...), etc.

weights.ebalance <- function(object, ...) {
  .active_group(object)$w_full
}

weights.ebalance.trim <- function(object, ...) {
  .active_group(object)$w_full
}

# ---- plot methods -----------------------------------------------------------
#
# Love plot: absolute standardized differences pre- and post-weighting,
# one row per covariate. Base graphics, no ggplot2 dependency.

plot.ebalance <- function(x,
                          type = c("balance", "weights"),
                          abs.values = TRUE,
                          xlab = NULL,
                          main = NULL,
                          ...) {
  type <- match.arg(type)
  if (is.null(x$Treatment) || is.null(x$X)) {
    stop("plot() requires the Treatment and X fields, which are stored ",
         "by the current package version. Refit to use plot().")
  }

  if (type == "weights") {
    return(.plot_ebalance_weights(x, main = main, xlab = xlab, ...))
  }

  # type = "balance" -- the original Love plot.
  if (is.null(xlab)) {
    xlab <- if (abs.values) "Absolute standardized difference"
            else "Standardized difference"
  }
  if (is.null(main)) {
    main <- "Covariate balance (before vs. after entropy balancing)"
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
  abline(v = 0, col = "grey80")
  points(pre[ord],  seq_len(k), pch = 1, col = "black")
  points(post[ord], seq_len(k), pch = 19, col = "darkblue")
  legend("topright",
         legend = c("before", "after"),
         pch = c(1, 19), col = c("black", "darkblue"),
         bty = "n", inset = 0.02)
  invisible(bal)
}

plot.ebalance.trim <- function(x, ...) plot.ebalance(x, ...)

# Internal: weight-distribution plot. Histogram(s) of the unit weights
# on whichever side(s) carry estimated weights. Subtitle reports the
# Kish ESS and max-weight ratio so the reader can see at a glance
# whether the fit is concentrated on a few units.
.plot_ebalance_weights <- function(x, main = NULL, xlab = NULL, ...) {
  ag <- .active_group(x)
  if (is.null(main)) {
    main <- sprintf("Weight distribution (%s)", ag$estimand)
  }
  if (is.null(xlab)) xlab <- "Unit weight"

  active <- switch(ag$reweighted,
                   controls = list(controls = ag$w_control),
                   treated  = list(treated = ag$w_treated),
                   both     = list(controls = ag$w_control,
                                   treated  = ag$w_treated))

  .ess <- function(w) sum(w)^2 / sum(w^2)
  .ratio <- function(w) max(w) / mean(w)
  sub <- paste(vapply(names(active), function(side) {
    w <- active[[side]]
    sprintf("%s: ESS = %.0f / %d, max/mean = %.2f",
            side, .ess(w), length(w), .ratio(w))
  }, character(1)), collapse = "   |   ")

  if (length(active) == 1) {
    op <- par(mar = c(5, 4, 4, 1))
    on.exit(par(op), add = TRUE)
    w <- active[[1]]
    hist(w, breaks = 30, main = main, xlab = xlab,
         col = "grey85", border = "grey40", ...)
    mtext(sub, side = 3, line = 0.2, cex = 0.85, col = "grey30")
  } else {
    op <- par(mfrow = c(1, 2), mar = c(5, 4, 4, 1), oma = c(0, 0, 2, 0))
    on.exit(par(op), add = TRUE)
    for (side in names(active)) {
      hist(active[[side]], breaks = 30,
           main = paste(side, "weights"), xlab = xlab,
           col = "grey85", border = "grey40", ...)
    }
    mtext(main, side = 3, line = 0, outer = TRUE, cex = 1.1, font = 2)
    mtext(sub,  side = 3, line = -1.2, outer = TRUE, cex = 0.85, col = "grey30")
  }
  invisible(active)
}
