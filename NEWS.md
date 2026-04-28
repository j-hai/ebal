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
