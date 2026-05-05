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
                     ...) {

  method <- match.arg(method)

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
    # Reject NAs explicitly, here, to match the matrix-interface
    # contract. Without this, model.matrix() below silently drops the
    # NA rows from X (default na.action) while model.response() above
    # kept them via na.pass — the result was a length-mismatch error
    # ("length(Treatment) != nrow(X)") instead of a clear "missing data"
    # message. Build the matrix from the same model frame to lock the
    # row alignment in either direction.
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
  # NA checks first: any non-finite Treatment value would otherwise
  # poison the binary check below (NA != 1 returns NA, which then
  # triggers "missing value where TRUE/FALSE needed" in the if()).
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

  if (is.null(base.weight)) {
    base.weight <- rep(1, ncontrols)
  }
  if (length(base.weight) != ncontrols) {
    stop("length(base.weight) !=  number of controls  sum(Treatment==0)")
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

  co.x <- X[Treatment == 0, , drop = FALSE]
  co.x <- cbind(rep(1, ncontrols), co.x)

  if (qr(co.x)$rank != ncol(co.x)) {
    stop("collinearity in covariate matrix for controls (remove collinear covariates)")
  }

  tr.total <- colSums(X[Treatment == 1, , drop = FALSE])

  if (is.null(norm.constant)) {
    norm.constant <- ntreated
  }
  if (length(norm.constant) != 1) {
    stop("length(norm.constant) != 1")
  }

  tr.total <- c(norm.constant, tr.total)

  if (is.null(coefs)) {
    coefs <- c(log(tr.total[1] / sum(base.weight)), rep(0, (ncol(co.x) - 1)))
  }

  if (length(coefs) != ncol(co.x)) {
    stop("coefs needs to have same length as number of covariates plus one")
  }

  # ---- run algorithm -------------------------------------------------------
  eb.out <- if (method == "newton") {
    eb(tr.total = tr.total,
       co.x = co.x,
       coefs = coefs,
       base.weight = base.weight,
       max.iterations = max.iterations,
       constraint.tolerance = constraint.tolerance,
       print.level = print.level)
  } else {
    .eb_autodiff(tr.total = tr.total,
                 co.x = co.x,
                 base.weight = base.weight,
                 max.iterations = max.iterations,
                 constraint.tolerance = constraint.tolerance,
                 print.level = print.level)
  }

  if (eb.out$converged && print.level > 0) {
    cat("Converged within tolerance \n")
  }

  z <- list(
    target.margins       = tr.total,
    co.xdata             = co.x,
    w                    = eb.out$Weights.ebal,
    coefs                = eb.out$coefs,
    maxdiff              = eb.out$maxdiff,
    norm.constant        = norm.constant,
    constraint.tolerance = constraint.tolerance,
    max.iterations       = max.iterations,
    base.weight          = base.weight,
    print.level          = print.level,
    converged            = eb.out$converged,
    Treatment            = Treatment.in,
    X                    = X
  )

  class(z) <- "ebalance"
  z
}
