ebalance <- function(Treatment,
                     X = NULL,
                     base.weight = NULL,
                     norm.constant = NULL,
                     coefs = NULL,
                     max.iterations = 200,
                     constraint.tolerance = 1,
                     print.level = 0,
                     data = NULL,
                     method = c("newton", "autodiff"),
                     estimand = c("ATT", "ATE", "ATC"),
                     ...) {

  method   <- match.arg(method)
  estimand <- match.arg(estimand)

  # ---- formula interface ---------------------------------------------------
  # If the user passed a two-sided formula as the first argument, build
  # Treatment and X from formula + data and continue with the matrix
  # interface. This is implemented as an in-function dispatch rather than
  # via S3 (UseMethod) to avoid a CRAN R CMD check NOTE that triggers when
  # ebalance is a generic and ebalance.trim — a long-standing top-level
  # function whose name accidentally matches the <generic>.<class> pattern
  # — looks like a method whose signature does not match the generic.
  if (inherits(Treatment, "formula")) {
    formula <- Treatment
    if (is.null(data)) {
      stop("'data' is required when calling ebalance() with a formula")
    }
    if (length(formula) != 3L) {
      stop("formula must be two-sided, e.g. treat ~ x1 + x2")
    }

    mf <- model.frame(formula, data = data, na.action = na.pass)
    treat <- model.response(mf)
    if (is.null(treat)) {
      stop("formula has no response (left-hand side); expected treat ~ x1 + x2 + ...")
    }
    if (any(is.na(treat)))
      stop("Treatment contains missing data")
    if (any(is.na(mf)))
      stop("X contains missing data")

    Xmat <- model.matrix(formula, data = mf)
    if ("(Intercept)" %in% colnames(Xmat)) {
      Xmat <- Xmat[, colnames(Xmat) != "(Intercept)", drop = FALSE]
    }

    Treatment <- treat
    X <- Xmat
  }

  # ---- input checks --------------------------------------------------------
  if (is.null(X)) {
    stop("'X' is required when 'Treatment' is not a formula")
  }
  if (sum(is.na(Treatment)) > 0) {
    stop("Treatment contains missing data")
  }
  if (sum(is.na(X)) > 0) {
    stop("X contains missing data")
  }
  if (sum(Treatment != 1 & Treatment != 0) > 0) {
    stop("Treatment indicator ('Treatment') must be a logical variable, TRUE (1) or FALSE (0)")
  }
  if (var(Treatment) == 0) {
    stop("Treatment indicator ('Treatment') must contain both treatment and control observations")
  }

  Treatment.in <- Treatment
  Treatment <- as.numeric(Treatment)
  X <- as.matrix(X)

  if (length(Treatment) != nrow(X)) {
    stop("length(Treatment) != nrow(X)")
  }
  if (length(max.iterations) != 1) {
    stop("length(max.iterations) != 1")
  }
  if (length(constraint.tolerance) != 1) {
    stop("length(constraint.tolerance) != 1")
  }

  # ---- setup ---------------------------------------------------------------
  ntreated  <- sum(Treatment == 1)
  ncontrols <- sum(Treatment == 0)
  ntotal    <- ntreated + ncontrols

  # ---- estimand dispatch ---------------------------------------------------
  # ATT: reweight controls to match treated moments. (Default; existing
  #      behavior unchanged.)
  # ATC: reweight treated to match control moments. Roles swapped from ATT.
  # ATE: reweight both groups to match overall sample moments. Two solves,
  #      one per group; output carries weights for both.
  if (estimand == "ATT") {
    z <- .eb_dispatch_one_side(
      donor_X         = X[Treatment == 0, , drop = FALSE],
      target_means    = colMeans(X[Treatment == 1, , drop = FALSE]),
      norm.constant   = norm.constant %||% ntreated,
      base.weight     = base.weight   %||% rep(1, ncontrols),
      n_donor_label   = "controls",
      n_donor         = ncontrols,
      coefs           = coefs,
      method          = method, max.iterations = max.iterations,
      constraint.tolerance = constraint.tolerance, print.level = print.level
    )
  } else if (estimand == "ATC") {
    z <- .eb_dispatch_one_side(
      donor_X         = X[Treatment == 1, , drop = FALSE],
      target_means    = colMeans(X[Treatment == 0, , drop = FALSE]),
      norm.constant   = norm.constant %||% ncontrols,
      base.weight     = base.weight   %||% rep(1, ntreated),
      n_donor_label   = "treated",
      n_donor         = ntreated,
      coefs           = coefs,
      method          = method, max.iterations = max.iterations,
      constraint.tolerance = constraint.tolerance, print.level = print.level
    )
  } else {
    # ATE: two solves, both targeting overall sample moments. Each side's
    # weights normalize to its own group n so weighted.mean(Y[T==t], w[T==t])
    # gives the population-level mean for each group; passing a scalar
    # norm.constant would override only one side and break that
    # interpretation, so we reject it explicitly rather than silently
    # accept an arg that has no scalar meaning here.
    if (!is.null(norm.constant)) {
      stop("norm.constant is not supported with estimand = \"ATE\"; the two sides normalize to ncontrols and ntreated respectively so weighted means recover population-level group means")
    }
    overall_means <- colMeans(X)
    # Allow a list(control=, treated=) for separate base weights, or a
    # single vector that's interpreted as the control side (treated
    # defaults to uniform).
    if (is.null(base.weight)) {
      bw_ctrl <- rep(1, ncontrols)
      bw_trt  <- rep(1, ntreated)
    } else if (is.list(base.weight)) {
      bw_ctrl <- base.weight$control %||% rep(1, ncontrols)
      bw_trt  <- base.weight$treated %||% rep(1, ntreated)
    } else {
      bw_ctrl <- base.weight
      bw_trt  <- rep(1, ntreated)
    }
    .check_bw <- function(bw, n, label) {
      if (length(bw) != n)
        stop(sprintf("length of base.weight for %s must equal %d", label, n))
      if (any(is.na(bw)) || any(!is.finite(bw)))
        stop(sprintf("base.weight for %s must be finite", label))
      if (any(bw < 0))
        stop(sprintf("base.weight for %s must be non-negative", label))
      if (sum(bw) <= 0)
        stop(sprintf("base.weight for %s must have positive sum", label))
    }
    .check_bw(bw_ctrl, ncontrols, "controls")
    .check_bw(bw_trt,  ntreated,  "treated")

    control_side <- .eb_solve_side(
      donor_X = X[Treatment == 0, , drop = FALSE],
      target_means = overall_means, norm_constant = ncontrols,
      base.weight = bw_ctrl, coefs = NULL,
      method = method, max.iterations = max.iterations,
      constraint.tolerance = constraint.tolerance, print.level = print.level
    )
    treated_side <- .eb_solve_side(
      donor_X = X[Treatment == 1, , drop = FALSE],
      target_means = overall_means, norm_constant = ntreated,
      base.weight = bw_trt, coefs = NULL,
      method = method, max.iterations = max.iterations,
      constraint.tolerance = constraint.tolerance, print.level = print.level
    )
    z <- list(
      estimand              = "ATE",
      Treatment             = Treatment.in,
      X                     = X,
      base.weight           = list(control = bw_ctrl, treated = bw_trt),
      norm.constant         = list(control = ncontrols, treated = ntreated),
      constraint.tolerance  = constraint.tolerance,
      max.iterations        = max.iterations,
      print.level           = print.level,
      control_solve         = control_side,
      treated_solve         = treated_side,
      # Backward-compat top-level fields point at the control side so
      # callers reading fit$w / fit$coefs / fit$target.margins still see
      # consistent shape; the treated-side fields are accessible via
      # fit$treated_solve$*.
      target.margins        = control_side$target.margins,
      co.xdata              = control_side$co.xdata,
      w                     = control_side$w,
      coefs                 = control_side$coefs,
      maxdiff               = max(control_side$maxdiff, treated_side$maxdiff),
      converged             = control_side$converged && treated_side$converged
    )
  }

  z$Treatment <- Treatment.in
  z$X         <- X
  z$estimand  <- estimand
  class(z)    <- "ebalance"
  z
}

# Internal: handle the single-solve case (ATT or ATC). Wraps the
# solver call and validation that's shared between the two role-symmetric
# estimands.
.eb_dispatch_one_side <- function(donor_X, target_means, norm.constant,
                                  base.weight, n_donor_label, n_donor,
                                  coefs, method, max.iterations,
                                  constraint.tolerance, print.level) {
  if (length(base.weight) != n_donor) {
    stop(sprintf("length(base.weight) != %d (number of %s)",
                 n_donor, n_donor_label))
  }
  if (any(is.na(base.weight)) || any(!is.finite(base.weight))) {
    stop("base.weight must be finite (no NA / NaN / Inf)")
  }
  if (any(base.weight < 0)) {
    stop("base.weight must be non-negative")
  }
  if (sum(base.weight) <= 0) {
    stop("base.weight must have positive sum")
  }
  if (length(norm.constant) != 1) {
    stop("length(norm.constant) != 1")
  }
  side <- .eb_solve_side(
    donor_X = donor_X, target_means = target_means,
    norm_constant = norm.constant, base.weight = base.weight,
    coefs = coefs,
    method = method, max.iterations = max.iterations,
    constraint.tolerance = constraint.tolerance, print.level = print.level
  )
  if (side$converged && print.level > 0) {
    cat("Converged within tolerance \n")
  }
  list(
    target.margins       = side$target.margins,
    co.xdata             = side$co.xdata,
    w                    = side$w,
    coefs                = side$coefs,
    maxdiff              = side$maxdiff,
    norm.constant        = norm.constant,
    constraint.tolerance = constraint.tolerance,
    max.iterations       = max.iterations,
    base.weight          = base.weight,
    print.level          = print.level,
    converged            = side$converged
  )
}

# Internal: actually call the solver for one (donor, target) pair.
# Exists so ATT/ATC/ATE all share a single code path through eb() /
# .eb_autodiff(), with the intercept column and norm.constant entry
# packed in the standard places.
.eb_solve_side <- function(donor_X, target_means, norm_constant,
                           base.weight, coefs, method,
                           max.iterations, constraint.tolerance,
                           print.level) {
  n <- nrow(donor_X)
  co.x <- cbind(rep(1, n), donor_X)
  if (qr(co.x)$rank != ncol(co.x)) {
    stop("collinearity in covariate matrix (remove collinear covariates)")
  }
  tr.total <- c(norm_constant, target_means * norm_constant)
  if (is.null(coefs)) {
    coefs <- c(log(tr.total[1] / sum(base.weight)), rep(0, ncol(co.x) - 1))
  }
  if (length(coefs) != ncol(co.x)) {
    stop("coefs needs to have same length as number of covariates plus one")
  }
  out <- if (method == "newton") {
    eb(tr.total = tr.total, co.x = co.x, coefs = coefs,
       base.weight = base.weight,
       max.iterations = max.iterations,
       constraint.tolerance = constraint.tolerance,
       print.level = print.level)
  } else {
    .eb_autodiff(tr.total = tr.total, co.x = co.x,
                 base.weight = base.weight,
                 coefs = coefs,
                 max.iterations = max.iterations,
                 constraint.tolerance = constraint.tolerance,
                 print.level = print.level)
  }
  list(
    target.margins = tr.total,
    co.xdata       = co.x,
    w              = out$Weights.ebal,
    coefs          = out$coefs,
    maxdiff        = out$maxdiff,
    converged      = out$converged
  )
}

`%||%` <- function(a, b) if (is.null(a)) b else a
