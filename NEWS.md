# ebal 0.3-0

## New: `balance_table()` exported

* `balance_table(fit)` returns a tidy per-covariate balance table with
  columns `variable`, `mean_treated_pre`, `mean_treated_post`,
  `mean_control_pre`, `mean_control_post`, `diff_pre`, `diff_post`,
  `std_diff_pre`, `std_diff_post`, `pct_reduction`. Carries
  `attr(out, "estimand")`. The table is the canonical balance
  representation for the package; `summary()`, `tidy()`, `plot()`,
  and `autoplot()` all read from it.

## New: weight-distribution plot

* `plot(fit, type = "weights")` and `autoplot(fit, type = "weights")`
  show histograms of the per-unit weights with the Kish ESS and
  max-weight ratio in the subtitle. `type = "balance"` (default) is
  the original Love plot.

## Enriched `glance()`

* `glance(fit)` now reports per-side ESS / max-weight diagnostics:
  `ess_control`, `ess_treated`, `max_weight_control`,
  `max_weight_treated`, `max_weight_ratio_control`,
  `max_weight_ratio_treated`. Also reports
  `max_abs_std_diff_pre` and `max_abs_std_diff_post` so the row is a
  one-glance "is this fit usable?" summary.

## API clarity

* Internal helper `.active_group(fit)` resolves the per-estimand side
  semantics in one place; `weights()`, `print()`, `glance()`, and the
  plot/autoplot/balance-table functions all route through it instead
  of re-implementing the estimand branch.
* `?ebalance` documents what `$w`, `weights(fit)`, `$target.margins`,
  `$norm.constant`, and `$base.weight` mean per estimand.
* `?ebalance` adds a section of formula-interface examples
  (`I(age^2)`, interactions, `factor(region)`).

## New vignettes

* `vignette("estimands", package = "ebal")` walks through ATT / ATC /
  ATE side by side: what gets reweighted, how `weights(fit)` shape
  changes, how to read the diagnostics.
* `vignette("outcome-models", package = "ebal")` shows the standard
  downstream-regression workflow: weighted `lm()`, robust SEs via
  `sandwich`/`lmtest` (in Suggests), survey-style inference, and when
  to add regression adjustment for a doubly-robust estimator.

## New: ATE / ATC estimands

* `ebalance()` gains an `estimand` argument: `"ATT"` (default; original
  behavior), `"ATC"` (treated reweighted to match controls; symmetric to
  ATT), `"ATE"` (both groups reweighted to match the overall sample).
* For `"ATE"` the returned object carries per-side solves under
  `$control_solve` and `$treated_solve`. `weights(fit)` returns a
  length-n vector with both groups carrying their estimated weights;
  drop straight into `lm(..., weights = w)` for the population ATE.
* `glance(fit)` now reports the `estimand`. `summary(fit)`, `plot(fit)`,
  `autoplot(fit)`, `tidy(fit)`, and `as.data.frame(fit)` all work
  unchanged across estimands; the underlying `.balance_table()` helper
  consumes a length-n weight vector so all three estimands route through
  the same display path.
* `ebalance.trim()` does not yet support `"ATE"` and refuses with a
  clear message; trim each side separately if needed.

## New: alternative solver via autodiff

* `ebalance()` gains a `method` argument: `"newton"` (default; the
  classical Newton-Raphson solver, behavior unchanged from earlier
  releases) and `"autodiff"` (a torch-based solver that uses BFGS on
  gradients computed by automatic differentiation).
* The `"autodiff"` path is contributed by Apoorva Lal, ported from his
  `ebal` fork at <https://github.com/apoorvalal/ebal>. It is more
  stable when the optimization landscape is poorly conditioned and
  scales better at large covariate counts. Newton remains the default
  because it is faster on the small problems that dominate everyday
  use; users opt into autodiff with `method = "autodiff"`.
* `torch` is in `Suggests:`, not `Imports:`. Users who do not use the
  autodiff path see no change to their installation footprint. The
  first call to a `torch` function in a session may require
  `torch::install_torch()` to download libtorch.
* Apoorva Lal added as `aut` on the package for this contribution.

## New: tidyverse-friendly extractors

* `tidy(fit)` returns a per-covariate balance table (means, raw and
  weighted differences, standardized differences) as a `data.frame`,
  ready for `dplyr` / `kable` / `gt` consumption. Methods registered
  against the `generics` package generics, so `library(broom)` makes
  them discoverable.
* `glance(fit)` returns a one-row summary: `n_treated`, `n_control`,
  `n_moments`, `sum_weights`, `ess_kish` (Kish effective sample size),
  `max_weight`, `max_weight_ratio`, `maxdiff`, `converged`. For
  `ebalance.trim` objects the row also carries `trim_feasible`.
* `augment(fit, data)` joins per-unit weights back to the original
  data frame as `.weight` (treated units get 1; controls get the
  ebalance weight). Drop-in for `lm(..., weights = .weight)`.
* `as.data.frame(fit)` returns the balance table directly (alias for
  `tidy()`'s output).

## New: ggplot2 Love plot

* `autoplot(fit)` returns a `ggplot` object showing the standardized
  difference of each covariate before vs. after weighting, with
  reference lines at 0 and ±0.1. Discoverable via `library(ggplot2)`;
  `ggplot2` is in `Suggests:`.

## New: vignette

* `vignette("ebal-quickstart", package = "ebal")` walks through the
  Lalonde PSID example end-to-end with both solver methods, the
  weighted regression follow-up, and the new tidy/autoplot output.

# ebal 0.2.1

## Internal restructure (no user-visible change)

* `ebalance()` is no longer an S3 generic. The formula vs. matrix
  dispatch is now handled inside the function via
  `inherits(Treatment, "formula")`. The user-facing API is unchanged:
  `ebalance(treat ~ x1 + x2, data = df)` and
  `ebalance(Treatment = t, X = X)` both work exactly as before.
  This change was made to satisfy CRAN's auto-checker, which flagged
  the long-standing top-level function `ebalance.trim()` as an
  "apparent method" of the `ebalance` generic and refused the 0.2.0
  submission.

# ebal 0.2.0

## Tooling and infrastructure

* `Authors@R` field replaces the older `Author` / `Maintainer` pair
  (current CRAN style).
* `Depends: methods` moved to `Imports: graphics, methods, stats` so
  the package no longer attaches its dependencies onto the user's
  search path.
* New `tests/testthat/` suite with 54 assertions covering the
  matrix and formula interfaces, the ebalance.trim graceful-fallback
  behavior, the new S3 methods, and the helper functions
  (`matrixmaker`, `getsquares`).
* `README.md` with quick-start examples for both the matrix and
  formula interfaces and a section on trimming.
* GitHub Actions CI workflow (`R-CMD-check.yaml`) runs against R
  release on macOS / Windows / Ubuntu, R devel on Ubuntu, and one
  prior R release on Ubuntu.

## New features (additive — old call signatures unchanged)

* **Formula interface.** `ebalance(treat ~ x1 + x2, data = df)` now
  works, in addition to the original `ebalance(Treatment = t, X = X)`
  matrix interface. Both produce identical numerical results. The
  formula interface uses `model.frame()` and `model.matrix()` and
  drops the `(Intercept)` column automatically.

* **`weights()` method.** `weights(fit)` returns a length-\eqn{n}
  vector aligned to the original `Treatment`: treated units get
  weight 1, control units get their entropy-balancing weight. Drop-in
  for `lm(..., weights = w)` or `survey::svyglm()`.

* **`print()` and `summary()` methods.** `print(fit)` shows a
  one-screen overview (counts, moments, convergence status, and for
  trimmed objects whether the trim target was feasible). `summary(fit)`
  returns a balance table comparing treated and control means
  (and standardized differences) before and after weighting.

* **`plot()` method.** Base-graphics Love plot of standardized
  differences before vs. after weighting, one row per covariate.
  No ggplot2 or other graphics dependency.

* **New return fields on `ebalance` and `ebalance.trim` objects:**
  `Treatment` (the original treatment indicator) and `X` (the original
  covariate matrix). Existing fields are unchanged. These enable the
  `summary()`, `plot()`, and `weights()` methods without requiring the
  user to pass the original data back in.

## Internal

* `ebalance` is now an S3 generic with `ebalance.default` (the
  workhorse with the matrix interface) and `ebalance.formula`
  (formula method) registered. `ebalance.trim` is intentionally NOT
  registered as a method; it remains a top-level function callable as
  `ebalance.trim(fit)` exactly as before. R CMD check emits an
  informational NOTE about the legacy name and we accept it.

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
