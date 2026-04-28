# =============================================================================
# Phase 3 fix-specific tests: formula interface and S3 methods
# =============================================================================
#
# How to run:
#   Rscript dev/05_phase3_tests.R
# =============================================================================

pkg_root <- getwd()
stopifnot(file.exists(file.path(pkg_root, "DESCRIPTION")))

templib <- tempfile("ebal_phase3_lib_")
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
    "for Phase 3 tests\n\n")

.fail <- 0L; .pass <- 0L
expect <- function(cond, label) {
  if (isTRUE(cond)) { cat(sprintf("  [PASS] %s\n", label)); .pass <<- .pass + 1L }
  else              { cat(sprintf("  [FAIL] %s\n", label)); .fail <<- .fail + 1L }
}

RNGkind("Mersenne-Twister", "Inversion", "Rejection")

# common test data
set.seed(20260427L)
treatment <- c(rep(0, 50), rep(1, 30))
X <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, 0.5)))
colnames(X) <- paste0("x", 1:3)
df <- data.frame(treat = treatment, X)

# =============================================================================
# Formula interface produces same result as matrix interface
# =============================================================================
cat("--- Formula interface ---\n")
{
  fit_mat <- ebalance(Treatment = treatment, X = X, print.level = 0)
  fit_for <- ebalance(treat ~ x1 + x2 + x3, data = df, print.level = 0)
  expect(inherits(fit_for, "ebalance"),
         "formula method returns ebalance object")
  expect(isTRUE(all.equal(fit_for$w, fit_mat$w, tolerance = 1e-12)),
         "formula and matrix interfaces produce identical weights")
  expect(isTRUE(all.equal(fit_for$coefs, fit_mat$coefs, tolerance = 1e-12)),
         "formula and matrix interfaces produce identical coefs")
  expect(identical(fit_for$converged, fit_mat$converged),
         "convergence status matches")

  # Errors
  err <- tryCatch(ebalance(treat ~ x1, data = NULL), error = function(e) e)
  expect(inherits(err, "error") && grepl("'data' is required", conditionMessage(err)),
         "formula without data errors with helpful message")

  err <- tryCatch(ebalance(~ x1, data = df), error = function(e) e)
  expect(inherits(err, "error"),
         "one-sided formula errors")
}

# =============================================================================
# Treatment and X stored on the object
# =============================================================================
cat("\n--- Treatment/X fields stored ---\n")
{
  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)
  expect(identical(as.numeric(fit$Treatment), as.numeric(treatment)),
         "Treatment is stored")
  expect(identical(fit$X, X),
         "X is stored")
}

# =============================================================================
# weights() returns full-length vector
# =============================================================================
cat("\n--- weights() S3 method ---\n")
{
  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)
  w <- weights(fit)
  expect(length(w) == length(treatment),
         "weights() returns length-n vector")
  expect(all(w[treatment == 1] == 1),
         "treated units get weight 1")
  expect(isTRUE(all.equal(w[treatment == 0], fit$w, tolerance = 1e-15)),
         "control units get the entropy-balancing weight")

  # Trim variant
  trimmed <- ebalance.trim(fit, print.level = 0)
  wt <- weights(trimmed)
  expect(length(wt) == length(treatment),
         "trim weights() returns length-n vector")
  expect(all(wt[treatment == 1] == 1),
         "treated units get weight 1 (trim)")
}

# =============================================================================
# print() methods
# =============================================================================
cat("\n--- print() methods ---\n")
{
  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)
  out <- capture.output(print(fit))
  expect(any(grepl("Entropy balancing", out)),
         "print.ebalance shows header")
  expect(any(grepl("Treated:", out)),
         "print.ebalance shows treated count")
  expect(any(grepl("Converged:", out)),
         "print.ebalance shows convergence")

  trimmed <- ebalance.trim(fit, print.level = 0)
  out2 <- capture.output(print(trimmed))
  expect(any(grepl("trimmed weights", out2)),
         "print.ebalance.trim shows trimmed header")
  expect(any(grepl("Trim feasible:", out2)),
         "print.ebalance.trim shows trim.feasible")
}

# =============================================================================
# summary() methods
# =============================================================================
cat("\n--- summary() methods ---\n")
{
  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)
  s <- summary(fit)
  expect(inherits(s, "summary.ebalance"),
         "summary returns class summary.ebalance")
  expect(is.data.frame(s$balance),
         "summary$balance is a data frame")
  expect(nrow(s$balance) == ncol(X),
         "balance table has one row per covariate")
  expected_cols <- c("mean.Tr", "mean.Co.pre", "mean.Co.post",
                     "diff.pre", "diff.post",
                     "std.diff.pre", "std.diff.post")
  expect(all(expected_cols %in% colnames(s$balance)),
         "balance table has expected columns")

  # post-weighting standardized differences should be small
  expect(all(abs(s$balance$std.diff.post) < 0.01),
         "post-weighting standardized differences near zero (well-balanced)")

  out <- capture.output(print(s))
  expect(any(grepl("Balance table", out)),
         "print.summary.ebalance prints a balance table heading")

  # Trim variant
  trimmed <- ebalance.trim(fit, print.level = 0)
  st <- summary(trimmed)
  expect(inherits(st, "summary.ebalance.trim"),
         "summary on trim returns class summary.ebalance.trim")
  expect(!is.null(st$call.info$trim.feasible),
         "trim summary includes trim.feasible")
}

# =============================================================================
# plot() methods (smoke test only — write to a temp PDF)
# =============================================================================
cat("\n--- plot() smoke test ---\n")
{
  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)
  pdf_path <- tempfile(fileext = ".pdf")
  pdf(pdf_path)
  bal <- tryCatch(plot(fit), error = function(e) e)
  trimmed <- ebalance.trim(fit, print.level = 0)
  bal2 <- tryCatch(plot(trimmed), error = function(e) e)
  dev.off()
  expect(!inherits(bal, "error"),
         "plot.ebalance does not error")
  expect(!inherits(bal2, "error"),
         "plot.ebalance.trim does not error")
  expect(file.exists(pdf_path) && file.size(pdf_path) > 0,
         "plot writes a non-empty PDF")
  unlink(pdf_path)
}

# =============================================================================
# Backward-compatibility: existing call signatures still work
# =============================================================================
cat("\n--- Backward compatibility ---\n")
{
  # Positional and named arguments
  fit_pos <- ebalance(treatment, X, print.level = 0)
  fit_nam <- ebalance(Treatment = treatment, X = X, print.level = 0)
  expect(isTRUE(all.equal(fit_pos$w, fit_nam$w, tolerance = 1e-15)),
         "positional and named first-arg calls produce identical weights")

  # ebalance.trim with named arg (legacy)
  trimmed <- ebalance.trim(ebalanceobj = fit_nam, print.level = 0)
  expect(inherits(trimmed, "ebalance.trim"),
         "ebalance.trim still accepts named ebalanceobj=")
}

# =============================================================================
cat(sprintf("\n%d passed, %d failed\n", .pass, .fail))
if (.fail > 0L) quit(save = "no", status = 1L)
quit(save = "no", status = 0L)
