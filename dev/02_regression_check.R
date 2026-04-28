# =============================================================================
# Regression check: current development source vs. frozen 0.1-8 baseline
# =============================================================================
#
# Purpose:
#   Install the *current* development source (the working tree) into a
#   temporary R library, run the exact same scenarios that 01_capture_baseline.R
#   used, and compare element-by-element against dev/baseline_0.1-8.rds.
#
#   This is the regression tripwire. Phases that claim "behavior preserving"
#   must produce identical results within `tol`. Phases that intentionally
#   fix bugs are expected to differ, and those differences are reported
#   explicitly and individually approved.
#
# How to run:
#   Rscript dev/02_regression_check.R               # default tol 1e-10
#   Rscript dev/02_regression_check.R --tol=1e-12   # tighter
#   Rscript dev/02_regression_check.R --verbose
#
# Exit code:
#   0  if all scenarios match (within tolerance)
#   1  if any scenario differs unexpectedly
# =============================================================================

# ---- args -------------------------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)
opt_tol <- 1e-10
opt_verbose <- FALSE
for (a in args) {
  if (grepl("^--tol=", a)) opt_tol <- as.numeric(sub("^--tol=", "", a))
  if (a == "--verbose") opt_verbose <- TRUE
}

# Scenarios that we KNOW differ from 0.1-8 due to intentional bug fixes.
# Each entry maps a scenario name to a short justification. After each fix
# is in place, add the scenario name here so the regression check passes
# again. Anything not listed here MUST match the baseline within `opt_tol`.
expected_diffs <- list(
  # Phase 1: ebalance.trim now populates $target.margins (was NULL in 0.1-8
  # because the code referenced ebalanceobj$tr.total which doesn't exist).
  s5_trim_auto = "Phase 1 fix A: target.margins now populated, was NULL in 0.1-8."
  # s4a_trim_mild and s4b_trim_aggressive still crash in 0.1-9 (same error
  # path); Phase 2 overflow guard will move them off this list.
)

# ---- locate paths -----------------------------------------------------------
# Run from package root: Rscript dev/02_regression_check.R
pkg_root <- getwd()
stopifnot(file.exists(file.path(pkg_root, "DESCRIPTION")))
baseline_rds <- file.path(pkg_root, "dev", "baseline_0.1-8.rds")
stopifnot(file.exists(baseline_rds))

# ---- install current source into isolated lib -------------------------------
templib <- tempfile("ebal_dev_lib_")
dir.create(templib)
cat("Installing current source from", pkg_root, "into temp lib...\n")
res <- system2(
  file.path(R.home("bin"), "R"),
  c("CMD", "INSTALL", "--no-multiarch", "-l", shQuote(templib),
    shQuote(pkg_root)),
  stdout = TRUE, stderr = TRUE
)
if (!is.null(attr(res, "status")) && attr(res, "status") != 0) {
  cat(res, sep = "\n")
  stop("R CMD INSTALL failed")
}

.libPaths(c(templib, .libPaths()))
suppressPackageStartupMessages(library(ebal, lib.loc = templib))
cat("Loaded ebal", as.character(packageVersion("ebal")),
    "from temp lib\n\n")

# ---- run scenarios (identical to 01_capture_baseline.R) ---------------------
RNGkind("Mersenne-Twister", "Inversion", "Rejection")

run_scenarios <- function() {
  out <- list()

  # s1
  set.seed(20260427L)
  treatment <- c(rep(0, 50), rep(1, 30))
  X <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, 0.5)))
  colnames(X) <- paste0("x", 1:3)
  out$s1_classic <- list(
    inputs = list(treatment = treatment, X = X),
    result = ebalance(Treatment = treatment, X = X, print.level = -1)
  )

  # s2
  set.seed(20260427L)
  treatment <- c(rep(0, 60), rep(1, 40))
  X <- matrix(c(rnorm(60, 0), rnorm(40, 0.7)), ncol = 1)
  colnames(X) <- "x1"
  fit <- tryCatch(
    ebalance(Treatment = treatment, X = X, print.level = -1),
    error = function(e) structure(list(error = conditionMessage(e)),
                                  class = "ebalance_error")
  )
  out$s2_single_cov <- list(
    inputs = list(treatment = treatment, X = X),
    result = fit
  )

  # s3
  set.seed(20260427L)
  treatment <- c(rep(0, 80), rep(1, 40))
  X <- rbind(replicate(4, rnorm(80, 0)), replicate(4, rnorm(40, 0.4)))
  colnames(X) <- paste0("x", 1:4)
  ncontrols <- sum(treatment == 0)
  bw <- runif(ncontrols, 0.5, 1.5)
  out$s3_baseweight <- list(
    inputs = list(treatment = treatment, X = X, base.weight = bw),
    result = ebalance(Treatment = treatment, X = X,
                      base.weight = bw, print.level = -1)
  )

  # s4a (mild trim, baseline crashes here)
  set.seed(20260427L)
  treatment <- c(rep(0, 100), rep(1, 50))
  X <- rbind(replicate(3, rnorm(100, 0)),
             replicate(3, rnorm(50, 0.6)))
  colnames(X) <- paste0("x", 1:3)
  fit <- ebalance(Treatment = treatment, X = X, print.level = -1)
  trimmed <- tryCatch(
    ebalance.trim(fit, max.weight = 5, print.level = -1),
    error = function(e) structure(list(error = conditionMessage(e)),
                                  class = "ebalance_error")
  )
  out$s4a_trim_mild <- list(
    inputs = list(treatment = treatment, X = X, max.weight = 5),
    result_ebalance = fit,
    result_trim = trimmed
  )

  # s4b (aggressive trim, baseline crashes here)
  set.seed(20260427L)
  treatment <- c(rep(0, 100), rep(1, 50))
  X <- rbind(replicate(3, rnorm(100, 0)),
             replicate(3, rnorm(50, 0.6)))
  colnames(X) <- paste0("x", 1:3)
  fit <- ebalance(Treatment = treatment, X = X, print.level = -1)
  trimmed <- tryCatch(
    ebalance.trim(fit, max.weight = 3, print.level = -1),
    error = function(e) structure(list(error = conditionMessage(e)),
                                  class = "ebalance_error")
  )
  out$s4b_trim_aggressive <- list(
    inputs = list(treatment = treatment, X = X, max.weight = 3),
    result_ebalance = fit,
    result_trim = trimmed
  )

  # s5
  set.seed(20260427L)
  treatment <- c(rep(0, 100), rep(1, 50))
  X <- rbind(replicate(3, rnorm(100, 0)),
             replicate(3, rnorm(50, 0.6)))
  colnames(X) <- paste0("x", 1:3)
  fit <- ebalance(Treatment = treatment, X = X, print.level = -1)
  out$s5_trim_auto <- list(
    inputs = list(treatment = treatment, X = X),
    result_ebalance = fit,
    result_trim = ebalance.trim(fit, print.level = -1)
  )

  # s6
  set.seed(20260427L)
  m <- matrix(rnorm(40), 10, 4)
  colnames(m) <- paste0("v", 1:4)
  out$s6_helpers <- list(
    inputs = list(m = m),
    result_matrixmaker = matrixmaker(m),
    result_getsquares  = getsquares(m)
  )

  out
}

current <- suppressMessages(run_scenarios())
baseline <- readRDS(baseline_rds)

# ---- compare ----------------------------------------------------------------
# Returns a character vector of differences (empty = identical within tol).
compare_one <- function(cur, base, path = "", tol = opt_tol) {
  if (inherits(cur, "ebalance_error") || inherits(base, "ebalance_error")) {
    if (inherits(cur, "ebalance_error") &&
        inherits(base, "ebalance_error")) {
      if (cur$error == base$error) {
        return(character())
      }
      return(sprintf("%s: error message changed (%s -> %s)", path,
                     base$error, cur$error))
    }
    return(sprintf("%s: error vs. result mismatch (cur=%s base=%s)", path,
                   if (inherits(cur, "ebalance_error")) "ERROR" else "OK",
                   if (inherits(base, "ebalance_error")) "ERROR" else "OK"))
  }
  if (is.list(cur) && is.list(base)) {
    diffs <- character()
    keys <- union(names(cur), names(base))
    for (k in keys) {
      diffs <- c(diffs, compare_one(cur[[k]], base[[k]],
                                    paste0(path, "$", k), tol))
    }
    return(diffs)
  }
  if (is.numeric(cur) && is.numeric(base)) {
    if (length(cur) != length(base)) {
      return(sprintf("%s: length differs (cur=%d base=%d)", path,
                     length(cur), length(base)))
    }
    if (length(cur) == 0L) return(character())
    md <- max(abs(cur - base), na.rm = TRUE)
    if (anyNA(cur) != anyNA(base)) {
      return(sprintf("%s: NA pattern differs", path))
    }
    if (is.finite(md) && md > tol) {
      return(sprintf("%s: max |diff| = %.3g > tol=%.1g", path, md, tol))
    }
    return(character())
  }
  if (is.character(cur) && is.character(base)) {
    if (!identical(cur, base)) {
      return(sprintf("%s: character mismatch", path))
    }
    return(character())
  }
  if (is.logical(cur) && is.logical(base)) {
    if (!identical(cur, base)) {
      return(sprintf("%s: logical mismatch (cur=%s base=%s)", path,
                     paste(cur, collapse = ","),
                     paste(base, collapse = ",")))
    }
    return(character())
  }
  if (!identical(cur, base)) {
    return(sprintf("%s: identical() failed", path))
  }
  character()
}

cat("Tolerance:", opt_tol, "\n")
cat("Comparing", length(current), "scenarios:\n\n")

unexpected <- 0L
expected_changed <- 0L
ok <- 0L
for (nm in names(baseline)) {
  if (!nm %in% names(current)) {
    cat(sprintf("  [MISSING] %s — not in current run\n", nm))
    unexpected <- unexpected + 1L
    next
  }
  diffs <- compare_one(current[[nm]], baseline[[nm]], path = nm)
  if (length(diffs) == 0L) {
    cat(sprintf("  [OK]      %s\n", nm))
    ok <- ok + 1L
  } else if (nm %in% names(expected_diffs)) {
    cat(sprintf("  [EXPECTED] %s — %s\n", nm, expected_diffs[[nm]]))
    if (opt_verbose) {
      for (d in diffs) cat(sprintf("            %s\n", d))
    }
    expected_changed <- expected_changed + 1L
  } else {
    cat(sprintf("  [DIFF]    %s\n", nm))
    for (d in diffs) cat(sprintf("            %s\n", d))
    unexpected <- unexpected + 1L
  }
}

cat(sprintf("\nSummary: %d ok, %d expected-changed, %d unexpected\n",
            ok, expected_changed, unexpected))
if (unexpected > 0L) {
  quit(save = "no", status = 1L)
}
quit(save = "no", status = 0L)
