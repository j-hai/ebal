# cran-comments.md

## Submission notes for ebal 0.2.0

This is a substantial update to the previously published ebal 0.1-8.

### What's new

* New formula interface: `ebalance(treat ~ x1 + x2, data = df)`
* New S3 methods: `print()`, `summary()`, `plot()`, `weights()` for both
  `ebalance` and `ebalance.trim` objects
* Numerical hardening: previously, aggressive `max.weight` targets in
  `ebalance.trim()` could trigger `exp()` overflow and crash with
  `"missing value where TRUE/FALSE needed"`. Both call sites now route
  through an internal `.safe_exp()` helper that caps the linear
  predictor at 700 before exponentiating; the explicit-target trim
  branch wraps the inner solve in `tryCatch()` and returns the most
  recent feasible fit (with `trim.feasible = FALSE` and a warning) on
  numerical failure.
* New `trim.feasible` field on `ebalance.trim` objects (logical).
* Several bug fixes in `ebalance.trim()` (target.margins field
  populated correctly), `ebalance()` (drop=FALSE on subset, silent
  default with print.level=0), and helpers.

All changes preserve the byte-for-byte numerical results of the prior
version on well-conditioned problems; this is verified by an internal
regression test (`dev/02_regression_check.R`) against the frozen
0.1-8 source.

### Test environments

* macOS Tahoe 26.3.1 (local), R 4.5.3
* Planned via GitHub Actions on submission: macOS-latest, ubuntu-latest,
  windows-latest with R release; ubuntu-latest with R devel and oldrel.

### R CMD check results

`R CMD check --as-cran` produces 2 NOTEs that we ask CRAN to accept:

1. **S3 generic/method consistency for `ebalance.trim`** —
   `ebalance.trim` is a top-level legacy function from version 0.1
   (2014) that pre-dates the introduction of the `ebalance` S3
   generic in this release. Its name accidentally follows the
   `<generic>.<class>` pattern, but it is not intended to be
   dispatched via `ebalance()` and is not registered as an S3 method
   in NAMESPACE. Renaming it would break a long-standing user-facing
   API; we accept the legacy name and the corresponding NOTE.

2. **`\usage` markup for `ebalance.trim.Rd`** — same root cause:
   because `ebalance.trim` is not an S3 method, we deliberately do
   not use `\method{ebalance}{trim}(...)` in its `\usage` block.
   Using `\method{}` would be misleading.

The other NOTEs from `--as-cran` are environment-specific (HTML math
rendering when V8 is unavailable; CRAN incoming feasibility URL
checks for our development repo) and will not appear on CRAN's build
machines.

### Reverse dependencies

`ebal` has 6 reverse dependencies on CRAN: `cobalt`, `fdid`, `hbal`,
`jointCalib`, `missDiag`, `rbw`. We ran `revdepcheck::revdep_check()`
comparing the new 0.2.0 against the CRAN baseline 0.1-8 on each:

* **0 new problems.** The 4 packages that built locally (`cobalt`,
  `fdid`, `missDiag`, `rbw`) check identically against both versions.
* **2 packages (`hbal`, `jointCalib`) failed to install** in our local
  environment because of a gfortran linker issue on macOS
  (`emutls_w` library not found). The failure is identical against
  both ebal versions (`## In both` in the revdep report), so it is
  an environment issue, not a regression introduced by 0.2.0. We
  expect CRAN's check farm to install both packages successfully.

We have additionally verified by direct inspection that:

* The exported function names and signatures of all pre-existing
  user-facing entry points (`ebalance`, `ebalance.trim`,
  `baltest.collect`, `eb`, `getsquares`, `line.searcher`,
  `matrixmaker`) are unchanged.
* The `ebalance` and `ebalance.trim` return objects retain every
  previously-documented field. Three new fields (`Treatment`, `X` on
  `ebalance`; plus `trim.feasible` on `ebalance.trim`) are added,
  which is purely additive.

### What we kept stable

* `ebalance(Treatment, X)` matrix interface — byte-for-byte unchanged
  on convergent inputs.
* All exported function names.
* All previously-documented return fields.
