# Smoke test that the README quick-start block runs end-to-end.
# This guards against the failure mode where a README example uses an
# undefined symbol (the missing `y` in the 0.3-0 RC).

test_that("README quick-start block runs end-to-end", {
  # Mirrors the block under "## Quick start" in README.md verbatim
  # (modulo whitespace).
  set.seed(1)
  treatment <- c(rep(0, 50), rep(1, 30))
  X <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, 0.5)))
  colnames(X) <- paste0("x", 1:3)
  df <- data.frame(treat = treatment, X)

  fit <- ebalance(treat ~ x1 + x2 + x3, data = df)
  expect_s3_class(fit, "ebalance")

  # Skip second matrix-form fit; it produces the same object and the
  # original README runs print/summary/plot on the second one.
  out_print   <- capture.output(print(fit))
  out_summary <- capture.output(print(summary(fit)))
  expect_true(any(grepl("Entropy balancing", out_print)))
  expect_true(any(grepl("Balance table", out_summary)))

  pdf(NULL); on.exit(dev.off(), add = TRUE)
  expect_silent(plot(fit))

  df$w <- weights(fit)
  df$y <- treatment + rnorm(nrow(df))
  mod <- lm(y ~ treat, data = df, weights = w)
  expect_s3_class(mod, "lm")
  expect_true("treat" %in% names(coef(mod)))
})

test_that("README trimming snippet runs", {
  set.seed(1)
  treatment <- c(rep(0, 50), rep(1, 30))
  X <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, 0.5)))
  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)

  trimmed <- ebalance.trim(fit, print.level = 0)
  expect_s3_class(trimmed, "ebalance.trim")

  trimmed2 <- ebalance.trim(fit, max.weight = 5, print.level = 0)
  expect_s3_class(trimmed2, "ebalance.trim")
})
