# ebal 0.1-10

## Numerical hardening

* `ebalance()` and `ebalance.trim()` no longer crash with
  `"missing value where TRUE/FALSE needed"` when the optimizer is
  pushed into a regime where `exp(co.x %*% coefs)` would overflow IEEE
  double precision. Both call sites now route through an internal
  `.safe_exp()` helper that caps the linear predictor at 700 before
  exponentiating. The cap is inactive (no observable effect) for
  well-conditioned problems; it activates when an aggressive
  `max.weight` target in `ebalance.trim()` forces the algorithm to
  explore very large coefficients, returning a large-but-finite weight
  so the line search and gradient check can keep navigating.

* `ebalance.trim()` now fails gracefully when the inner Newton solve
  becomes numerically singular during the explicit-`max.weight` branch
  (for example, because the requested target is infeasible). It emits
  a clear warning, returns the most recent feasible fit, and sets the
  new `trim.feasible` field to `FALSE`. Previously it crashed with
  `"system is computationally singular"` (or, before the overflow
  guard, the older `NaN` error). The automatic-minimization branch
  was already wrapped in `try()` and is unchanged.

* New return field `trim.feasible` (logical) on `ebalance.trim`
  objects. `TRUE` when an explicit target was met or when automatic
  minimization completed; `FALSE` when an explicit target proved
  infeasible. Existing fields are unchanged; reading any other field
  by name continues to work as before.

* `ebalance()` uses `colSums()` instead of `apply(X, 2, sum)` to
  compute treatment-group target margins. Output is identical;
  trivially faster and avoids an unnecessary `as.matrix()` wrap.

## Decision noted: Cholesky solve not adopted

* The Hessian `H = X' diag(w) X` is symmetric positive semidefinite,
  so a Cholesky-based solve would be the textbook choice. We
  considered switching from `solve(H, gradient)` to `chol2inv(chol(H))`
  but kept `solve()` because (a) the Hessian is small in this package
  (covariates × covariates, typically < 50 × 50), so the speed
  difference is negligible, and (b) Cholesky and LU agree only at
  machine precision, which would introduce last-bit drift versus the
  0.1-8 baseline that we have no compelling reason to accept.

# ebal 0.1-9

## Bug fixes

* `ebalance.trim()` now correctly populates the `target.margins` field of
  the returned object. Previously it referenced a non-existent
  `ebalanceobj$tr.total` and silently returned `NULL`.
* `ebalance()` now uses `drop = FALSE` when subsetting the control rows
  of `X`, eliminating a latent dimension-drop issue that was masked by
  `cbind()` in the next line.

## Quiet by default

* With the default `print.level = 0`, neither `ebalance()` nor
  `ebalance.trim()` emits per-iteration progress messages or a
  "Converged within tolerance" line. Set `print.level = 1` to restore
  the previous chatter; `2` and `3` give increasing detail.

## Internal cleanups (no user-visible change)

* `eb()`: removed a redundant call to `solve(hessian, gradient)` after
  the line search; the Newton direction is now reused.
* `getsquares()`: replaced `dim(table(x)) > 2` with
  `length(unique(x)) > 2`; same predicate, faster on large vectors.
* `matrixmaker()`: dropped an unused "dummy" column that was allocated
  and then discarded before return.
* `zzz.r`: removed unused `this.year` computation; switched startup
  message URL to https.
* `ebalance.trim.Rd`: `\seealso` now correctly cross-references
  `ebalance` instead of itself.
* `print.level` documentation in `ebalance.Rd` and `ebalance.trim.Rd`
  now lists all four levels (0, 1, 2, 3) the code actually supports.
