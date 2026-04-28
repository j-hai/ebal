# =============================================================================
# Phase 2 fix-specific tests
# =============================================================================
#
# Numerical hardening: overflow guard, graceful failure on infeasible
# trim targets, trim.feasible flag.
#
# How to run:
#   Rscript dev/04_phase2_tests.R
# =============================================================================

pkg_root <- getwd()
stopifnot(file.exists(file.path(pkg_root, "DESCRIPTION")))

templib <- tempfile("ebal_phase2_lib_")
dir.create(templib)
res <- system2(file.path(R.home("bin"), "R"),
               c("CMD", "INSTALL", "--no-multiarch",
                 "-l", shQuote(templib), shQuote(pkg_root)),
               stdout = TRUE, stderr = TRUE)
if (!is.null(attr(res, "status")) && attr(res, "status") != 0) {
  cat(res, sep = "\n"); stop("install failed")
}
.libPaths(c(templib, .libPaths()))
suppressPackageStartupMessages(library(ebal, lib.loc = templib))
cat("Loaded ebal", as.character(packageVersion("ebal")),
    "for Phase 2 tests\n\n")

.fail <- 0L; .pass <- 0L
expect <- function(cond, label) {
  if (isTRUE(cond)) { cat(sprintf("  [PASS] %s\n", label)); .pass <<- .pass + 1L }
  else              { cat(sprintf("  [FAIL] %s\n", label)); .fail <<- .fail + 1L }
}

RNGkind("Mersenne-Twister", "Inversion", "Rejection")

# =============================================================================
# Overflow guard: .safe_exp is internal but we can probe it via behavior.
# A scenario that would have crashed in 0.1-8 now returns a usable object.
# =============================================================================
cat("--- Overflow guard: trim with infeasible max.weight no longer crashes ---\n")
{
  set.seed(20260427L)
  treatment <- c(rep(0, 100), rep(1, 50))
  X <- rbind(replicate(3, rnorm(100, 0)),
             replicate(3, rnorm(50, 0.6)))
  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)

  trimmed <- suppressWarnings(
    ebalance.trim(fit, max.weight = 3, print.level = 0)
  )
  expect(inherits(trimmed, "ebalance.trim"),
         "infeasible max.weight returns ebalance.trim object (not error)")
  expect(identical(trimmed$trim.feasible, FALSE),
         "trim.feasible is FALSE when target was not met")
  expect(length(trimmed$w) == 100,
         "weights vector has correct length")
  expect(all(is.finite(trimmed$w)),
         "all returned weights are finite (no Inf/NaN)")
}

# =============================================================================
# Achievable target: trim.feasible should be TRUE
# =============================================================================
cat("\n--- Achievable target: trim.feasible = TRUE ---\n")
{
  set.seed(20260427L)
  treatment <- c(rep(0, 100), rep(1, 50))
  X <- rbind(replicate(3, rnorm(100, 0)),
             replicate(3, rnorm(50, 0.6)))
  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)

  # First check what max ratio the fit produces — pick a comfortably
  # achievable target above it.
  base.ratio <- max(fit$w / mean(fit$w))
  target <- base.ratio * 1.5
  trimmed <- ebalance.trim(fit, max.weight = target, print.level = 0)
  expect(identical(trimmed$trim.feasible, TRUE),
         "trim.feasible is TRUE when easy target met")
  expect(max(trimmed$w / mean(trimmed$w)) <= target,
         "achieved max weight ratio is at or below target")
}

# =============================================================================
# Auto-minimization mode: trim.feasible = TRUE by definition
# =============================================================================
cat("\n--- Auto-minimization: trim.feasible = TRUE by definition ---\n")
{
  set.seed(20260427L)
  treatment <- c(rep(0, 100), rep(1, 50))
  X <- rbind(replicate(3, rnorm(100, 0)),
             replicate(3, rnorm(50, 0.6)))
  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)
  trimmed <- ebalance.trim(fit, print.level = 0)
  expect(identical(trimmed$trim.feasible, TRUE),
         "trim.feasible is TRUE in auto-minimization mode")
}

# =============================================================================
# Warning is emitted on infeasible explicit target
# =============================================================================
cat("\n--- Warning on infeasible target ---\n")
{
  set.seed(20260427L)
  treatment <- c(rep(0, 100), rep(1, 50))
  X <- rbind(replicate(3, rnorm(100, 0)),
             replicate(3, rnorm(50, 0.6)))
  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)

  warned <- FALSE
  withCallingHandlers(
    ebalance.trim(fit, max.weight = 3, print.level = 0),
    warning = function(w) {
      if (grepl("Trimming halted", conditionMessage(w))) warned <<- TRUE
      invokeRestart("muffleWarning")
    }
  )
  expect(warned, "warning is emitted when target infeasible")
}

# =============================================================================
# Summary
# =============================================================================
cat(sprintf("\n%d passed, %d failed\n", .pass, .fail))
if (.fail > 0L) quit(save = "no", status = 1L)
quit(save = "no", status = 0L)
