# =============================================================================
# Capture golden-baseline outputs from ebal 0.1-8 (frozen reference)
# =============================================================================
#
# Purpose:
#   Install the frozen 0.1-8 tarball into a TEMPORARY library that does not
#   collide with the user's normal R library, run a fixed-seed set of toy
#   examples that exercise both ebalance() and ebalance.trim(), and save
#   the results to an RDS file. Subsequent phases (bug fixes, numerical
#   hardening, API additions) compare against this RDS to detect any
#   unintended behavior change.
#
# How to run:
#   Rscript dev/01_capture_baseline.R
#
# Outputs:
#   dev/baseline_0.1-8.rds   — list of named results, see scenarios below
#   dev/baseline_0.1-8.log   — sessionInfo and timing
#
# This script must be re-runnable and produce identical RDS bytes (modulo
# attributes that depend on R version) on a given machine.
# =============================================================================

suppressPackageStartupMessages({
  # nothing here yet; ebal is loaded after install into a temp lib
})

# ---- locate paths -----------------------------------------------------------
script_dir <- if (sys.nframe() > 0) {
  tryCatch(
    dirname(normalizePath(sys.frame(1)$ofile, mustWork = FALSE)),
    error = function(e) getwd()
  )
} else {
  getwd()
}
# When invoked via Rscript from package root, sys.frame(1)$ofile is set;
# fall back to the conventional layout.
if (!file.exists(file.path(script_dir, "ebal_0.1-8_baseline.tar.gz"))) {
  # likely invoked from package root
  if (file.exists("dev/ebal_0.1-8_baseline.tar.gz")) {
    script_dir <- file.path(getwd(), "dev")
  }
}
tarball <- file.path(script_dir, "ebal_0.1-8_baseline.tar.gz")
stopifnot(file.exists(tarball))

baseline_rds <- file.path(script_dir, "baseline_0.1-8.rds")
baseline_log <- file.path(script_dir, "baseline_0.1-8.log")

# ---- install into an isolated library --------------------------------------
templib <- tempfile("ebal_baseline_lib_")
dir.create(templib)
cat("Installing", basename(tarball), "into", templib, "\n")
install.packages(tarball, repos = NULL, type = "source", lib = templib,
                 quiet = TRUE, INSTALL_opts = "--no-multiarch")

# Load from the temp library only.
.libPaths(c(templib, .libPaths()))
suppressPackageStartupMessages(library(ebal, lib.loc = templib))
stopifnot(packageVersion("ebal") == "0.1-8")

# ---- deterministic test scenarios ------------------------------------------
# We deliberately use simple, reproducible scenarios. Anything that depends
# on RNG must use a fixed seed AND a documented RNGkind.
RNGkind("Mersenne-Twister", "Inversion", "Rejection")

scenarios <- list()

# Scenario 1: classic 3-covariate toy from ebalance.Rd ------------------------
set.seed(20260427L)
{
  treatment <- c(rep(0, 50), rep(1, 30))
  X <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, 0.5)))
  colnames(X) <- paste0("x", 1:3)
  fit <- ebalance(Treatment = treatment, X = X, print.level = -1)
  scenarios$s1_classic <- list(
    inputs = list(treatment = treatment, X = X),
    result = fit
  )
}

# Scenario 2: single covariate (exercises the drop=FALSE bug fix later) -------
set.seed(20260427L)
{
  treatment <- c(rep(0, 60), rep(1, 40))
  X <- matrix(c(rnorm(60, 0), rnorm(40, 0.7)), ncol = 1)
  colnames(X) <- "x1"
  fit <- tryCatch(
    ebalance(Treatment = treatment, X = X, print.level = -1),
    error = function(e) structure(list(error = conditionMessage(e)),
                                  class = "ebalance_error")
  )
  scenarios$s2_single_cov <- list(
    inputs = list(treatment = treatment, X = X),
    result = fit
  )
}

# Scenario 3: with non-uniform base weights -----------------------------------
set.seed(20260427L)
{
  treatment <- c(rep(0, 80), rep(1, 40))
  X <- rbind(replicate(4, rnorm(80, 0)), replicate(4, rnorm(40, 0.4)))
  colnames(X) <- paste0("x", 1:4)
  ncontrols <- sum(treatment == 0)
  bw <- runif(ncontrols, 0.5, 1.5)
  fit <- ebalance(Treatment = treatment, X = X,
                  base.weight = bw, print.level = -1)
  scenarios$s3_baseweight <- list(
    inputs = list(treatment = treatment, X = X, base.weight = bw),
    result = fit
  )
}

# Scenario 4a: trim with mild explicit max.weight -----------------------------
set.seed(20260427L)
{
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
  scenarios$s4a_trim_mild <- list(
    inputs = list(treatment = treatment, X = X, max.weight = 5),
    result_ebalance = fit,
    result_trim = trimmed
  )
}

# Scenario 4b: trim with aggressive max.weight (KNOWN CRASH in 0.1-8) ---------
# Records the failure so later phases can demonstrate the fix.
set.seed(20260427L)
{
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
  # Note: 0.1-8 crashes here due to overflow in exp(); Phase 2 should fix.
  scenarios$s4b_trim_aggressive <- list(
    inputs = list(treatment = treatment, X = X, max.weight = 3),
    result_ebalance = fit,
    result_trim = trimmed
  )
}

# Scenario 5: trim with default (auto-minimization) ---------------------------
set.seed(20260427L)
{
  treatment <- c(rep(0, 100), rep(1, 50))
  X <- rbind(replicate(3, rnorm(100, 0)),
             replicate(3, rnorm(50, 0.6)))
  colnames(X) <- paste0("x", 1:3)
  fit <- ebalance(Treatment = treatment, X = X, print.level = -1)
  trimmed <- ebalance.trim(fit, print.level = -1)
  scenarios$s5_trim_auto <- list(
    inputs = list(treatment = treatment, X = X),
    result_ebalance = fit,
    result_trim = trimmed
  )
}

# Scenario 6: helper utilities ------------------------------------------------
set.seed(20260427L)
{
  m <- matrix(rnorm(40), 10, 4)
  colnames(m) <- paste0("v", 1:4)
  scenarios$s6_helpers <- list(
    inputs = list(m = m),
    result_matrixmaker = matrixmaker(m),
    result_getsquares  = getsquares(m)
  )
}

# ---- save -------------------------------------------------------------------
saveRDS(scenarios, baseline_rds, version = 2)
sink(baseline_log)
cat("ebal version:  ", as.character(packageVersion("ebal")), "\n", sep = "")
cat("R version:     ", R.version.string, "\n", sep = "")
cat("captured at:   ", format(Sys.time(), tz = "UTC", usetz = TRUE), "\n", sep = "")
cat("RDS:           ", baseline_rds, "\n", sep = "")
cat("scenarios:     ", length(scenarios), " (", paste(names(scenarios), collapse = ", "), ")\n", sep = "")
cat("\n--- sessionInfo ---\n")
print(sessionInfo())
sink()

cat("Wrote", baseline_rds, "\n")
cat("Wrote", baseline_log, "\n")
