# =============================================================================
# Benchmark ebal 0.2.0 against WeightIt::weightit(method = "ebal")
# =============================================================================
#
# Two questions:
#   (a) Numerical equivalence — given identical data and target moments,
#       do the two implementations converge to the same weights?
#   (b) Speed — at what problem sizes does each implementation matter?
#
# How to run:
#   Rscript dev/06_benchmark.R
# =============================================================================

pkg_root <- getwd()
templib <- tempfile("ebal_bench_lib_")
dir.create(templib)
suppressWarnings(install.packages(pkg_root, repos = NULL, type = "source",
                                  lib = templib, quiet = TRUE))
.libPaths(c(templib, .libPaths()))
suppressPackageStartupMessages({
  library(ebal,           lib.loc = templib)
  library(WeightIt)
  library(microbenchmark)
})

cat("ebal version:    ", as.character(packageVersion("ebal")),     "\n")
cat("WeightIt version:", as.character(packageVersion("WeightIt")), "\n\n")

# ---- helpers ---------------------------------------------------------------
make_data <- function(n_treated, n_control, k_covs, seed = 1L) {
  set.seed(seed)
  Xt <- matrix(rnorm(n_treated * k_covs, mean = 0.4), nrow = n_treated)
  Xc <- matrix(rnorm(n_control * k_covs, mean = 0.0), nrow = n_control)
  treat <- c(rep(1L, n_treated), rep(0L, n_control))
  X <- rbind(Xt, Xc)
  colnames(X) <- paste0("x", seq_len(k_covs))
  list(treat = treat, X = X,
       df = data.frame(treat = treat, X))
}

# Extract a length-n weight vector aligned to the original treatment from
# either an ebal or a WeightIt fit.
get_full_weights <- function(fit, treat) {
  if (inherits(fit, "ebalance")) return(weights(fit))
  if (inherits(fit, "weightit")) return(fit$weights)
  stop("unknown fit class: ", class(fit)[1])
}

# Compare two weight vectors after normalizing both so sum(weights[control]) = 1
# (normalization differs across packages: ebal uses sum = ntreated; WeightIt
# typically normalizes to sum = ntreated as well for ATT, but be safe).
compare_weights <- function(w1, w2, treat) {
  w1c <- w1[treat == 0]
  w2c <- w2[treat == 0]
  w1c <- w1c / sum(w1c)
  w2c <- w2c / sum(w2c)
  list(
    max_abs_diff = max(abs(w1c - w2c)),
    cor          = cor(w1c, w2c),
    rmse         = sqrt(mean((w1c - w2c)^2))
  )
}

# ---- (a) numerical equivalence ---------------------------------------------
cat("============== Numerical equivalence ==============\n\n")

d <- make_data(n_treated = 100, n_control = 400, k_covs = 5, seed = 20260427L)

fit_ebal <- ebalance(treat ~ x1 + x2 + x3 + x4 + x5, data = d$df,
                     constraint.tolerance = 1e-8)
fit_wtit <- weightit(treat ~ x1 + x2 + x3 + x4 + x5, data = d$df,
                     method = "ebal", estimand = "ATT")

cat("ebal fit converged:    ", fit_ebal$converged,
    "  max moment dev:", signif(fit_ebal$maxdiff, 3), "\n")

w_ebal <- get_full_weights(fit_ebal, d$treat)
w_wtit <- get_full_weights(fit_wtit, d$treat)

cmp <- compare_weights(w_ebal, w_wtit, d$treat)
cat("\nweight comparison (controls only, normalized to sum = 1):\n")
cat("  max |diff|:", signif(cmp$max_abs_diff, 3), "\n")
cat("  RMSE:      ", signif(cmp$rmse, 3),         "\n")
cat("  cor(w):    ", signif(cmp$cor, 6),          "\n\n")

# Independent check: do both achieve covariate balance?
control_idx <- d$treat == 0
treated_idx <- d$treat == 1
treated_means <- colMeans(d$X[treated_idx, , drop = FALSE])

w_ebal_c <- w_ebal[control_idx]
w_wtit_c <- w_wtit[control_idx]

ebal_post <- apply(d$X[control_idx, ], 2, weighted.mean, w = w_ebal_c)
wtit_post <- apply(d$X[control_idx, ], 2, weighted.mean, w = w_wtit_c)

cat("Reweighted control means vs. treated means (per covariate):\n\n")
tbl <- data.frame(
  treated_mean        = treated_means,
  ebal_post           = ebal_post,
  ebal_diff           = ebal_post - treated_means,
  WeightIt_post       = wtit_post,
  WeightIt_diff       = wtit_post - treated_means
)
print(round(tbl, 6))

# ---- (b) speed --------------------------------------------------------------
cat("\n\n============== Speed (microbenchmark, 5 reps) ==============\n\n")

run_bench <- function(n_treated, n_control, k, label) {
  cat(sprintf("--- %s: n_treated = %d, n_control = %d, k_covs = %d ---\n",
              label, n_treated, n_control, k))
  d <- make_data(n_treated, n_control, k, seed = 1L)
  rhs <- paste(paste0("x", seq_len(k)), collapse = " + ")
  fmla <- as.formula(paste("treat ~", rhs))

  bm <- microbenchmark(
    ebal     = ebalance(fmla, data = d$df, constraint.tolerance = 1e-6),
    WeightIt = weightit(fmla, data = d$df, method = "ebal", estimand = "ATT"),
    times = 5L,
    unit  = "ms"
  )
  print(summary(bm)[, c("expr", "min", "median", "mean", "max")])
  cat("\n")
}

run_bench(  100,  1000, 5, "small")
run_bench(  500,  5000, 5, "medium")
run_bench( 1000, 10000, 5, "large")
run_bench( 1000, 10000, 20, "wide (more covariates)")
