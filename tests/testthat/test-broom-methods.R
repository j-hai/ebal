.fit_toy <- function() {
  set.seed(20260504L)
  treatment <- c(rep(0, 50), rep(1, 30))
  X <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, 0.5)))
  colnames(X) <- paste0("x", 1:3)
  ebalance(Treatment = treatment, X = X, print.level = 0)
}

test_that("tidy.ebalance returns a per-covariate balance table", {
  fit <- .fit_toy()
  out <- tidy.ebalance(fit)
  expect_named(out, c("term", "mean_treated", "mean_control",
                      "mean_control_w", "diff_pre", "diff_post",
                      "std_diff_pre", "std_diff_post"))
  expect_equal(nrow(out), 3L)
  # Post-weighting standardized differences should be much smaller
  expect_true(all(abs(out$std_diff_post) <= abs(out$std_diff_pre) + 1e-6))
})

test_that("glance.ebalance returns one row of summary stats", {
  fit <- .fit_toy()
  out <- glance.ebalance(fit)
  expect_equal(nrow(out), 1L)
  expect_named(out, c("n_treated", "n_control", "n_moments",
                      "sum_weights", "ess_kish", "max_weight",
                      "max_weight_ratio", "maxdiff", "converged"))
  expect_equal(out$n_treated, 30L)
  expect_equal(out$n_control, 50L)
  expect_true(out$converged)
})

test_that("augment.ebalance joins .weight back to the data", {
  fit <- .fit_toy()
  out <- augment.ebalance(fit)
  # No data supplied → default to .weight + .treatment + X
  expect_true(".weight" %in% names(out))
  expect_true(".treatment" %in% names(out))
  # treated units get weight 1
  expect_true(all(out$.weight[out$.treatment == 1] == 1))
  # control weights match fit$w
  expect_equal(out$.weight[out$.treatment == 0], fit$w)
})

test_that("as.data.frame.ebalance returns the tidy balance table", {
  fit <- .fit_toy()
  out <- as.data.frame(fit)
  expect_named(out, c("term", "mean_treated", "mean_control",
                      "mean_control_w", "diff_pre", "diff_post",
                      "std_diff_pre", "std_diff_post"))
  expect_equal(nrow(out), 3L)
})
