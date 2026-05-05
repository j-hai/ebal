# Autodiff entropy balancing via the `torch` package.
#
# Ported from Apoorva Lal's torch_eb.R in github.com/apoorvalal/ebal
# (GPL >= 2; same license as this package). The mathematical content
# is identical to the Newton-Raphson solver in eb.R: minimize the dual
#
#   L(lambda) = log( q . exp(-X0' lambda) ) + lambda' x1
#
# where X0 is the (n_control x k) covariate matrix with the leading
# constant column, q is the base-weight vector, and x1 is the vector
# of target moments (norm.constant + column sums of treated X).
#
# Newton-Raphson is fast and exact when the Hessian is well-conditioned;
# autodiff (BFGS on the gradient computed via torch::autograd_grad) is
# more stable when the optimization landscape is poorly conditioned and
# scales better on large k. The two methods produce equivalent weights
# within solver tolerance.

.eb_autodiff <-
function(tr.total, co.x, base.weight,
         max.iterations = 200, constraint.tolerance = 1, print.level = 0)
  {
    if (!requireNamespace("torch", quietly = TRUE))
      stop("torch is not installed. Install with: install.packages(\"torch\"); torch::install_torch()")
    if (!torch::torch_is_installed())
      stop("libtorch backend not installed. Run: torch::install_torch()")

    # Strip the leading constant column / norm.constant entry that
    # ebalance() prepends for the Newton-Raphson workhorse — Lal's
    # autodiff loss matches *means* on the non-constant covariates and
    # handles normalization explicitly. Recovering the eb() output
    # convention (weights sum to norm.constant) is then a single
    # post-hoc scaling step.
    norm.constant <- tr.total[1]
    X0 <- as.matrix(co.x[, -1, drop = FALSE])
    X1 <- as.numeric(tr.total[-1] / norm.constant)  # treated means
    q  <- as.numeric(base.weight) / sum(base.weight)  # base distribution sums to 1

    inp <- list(
      x0 = torch::torch_tensor(X0),
      x1 = torch::torch_tensor(X1),
      q  = torch::torch_tensor(q)
    )

    # Dual objective for the entropy-balancing problem with normalized
    # weights summing to 1 and matching means X1:
    #   L(lambda) = log( q . exp(-X0 lambda) ) + lambda . X1
    ebal_loss <- function(lambda) {
      inner <- inp$q$dot(torch::torch_exp(-1 * torch::torch_matmul(inp$x0, lambda)))
      torch::torch_log(inner) + torch::torch_matmul(lambda, inp$x1)
    }
    loss_grad <- function(lambda) {
      lambda_ad <- torch::torch_tensor(lambda, requires_grad = TRUE)
      g <- torch::autograd_grad(ebal_loss(lambda_ad), lambda_ad)[[1]]
      as.numeric(g)
    }
    loss_val <- function(lambda) as.numeric(ebal_loss(lambda))

    # Zero-init: at lambda = 0 the loss equals log(sum(q)) = 0 (q is
    # already normalized to sum 1) and the gradient is X1 - mean_q(X0)
    # — i.e. the imbalance under the base distribution. BFGS converges
    # quickly from there for well-conditioned problems.
    par0 <- rep(0, ncol(X0))

    res <- optim(par = par0, fn = loss_val, gr = loss_grad,
                 method = "BFGS",
                 control = list(maxit = max.iterations,
                                reltol = 1e-12,
                                trace = if (print.level > 1) 1 else 0))

    # Reconstruct the primal weights and rescale to the eb() convention
    # (sum to norm.constant rather than 1) so downstream methods match.
    coefs_meanform <- res$par
    w_norm <- q * exp(-as.numeric(X0 %*% coefs_meanform))
    w_norm <- w_norm / sum(w_norm)
    w      <- w_norm * norm.constant

    # Deviation of moments under the recovered weights from the targets.
    moments_attained <- as.numeric(c(sum(w), t(X0) %*% w))
    maxdiff <- max(abs(moments_attained - tr.total))

    # Map the mean-form coefs back into the augmented co.x shape so
    # base.weight * exp(co.x %*% coefs) reproduces fit$w. From the
    # primal-form
    #   w[i] = (base.weight[i] / S) * exp(-X0[i,] %*% lambda) / Z * N
    #   eb form: w[i] = base.weight[i] * exp(c0 + X0[i,] %*% c_rest)
    # equating gives c_rest = -lambda and
    #   c0 = log(N / S) - log(Z)
    # where S = sum(base.weight), N = norm.constant, and Z is the
    # partition function evaluated at the optimum.
    log_Z <- log(sum(q * exp(-as.numeric(X0 %*% coefs_meanform))))
    c0 <- log(norm.constant / sum(base.weight)) - log_Z
    coefs_full <- c(c0, -coefs_meanform)

    list(
      coefs        = coefs_full,
      Weights.ebal = w,
      maxdiff      = maxdiff,
      converged    = (res$convergence == 0) && (maxdiff < constraint.tolerance)
    )
  }
