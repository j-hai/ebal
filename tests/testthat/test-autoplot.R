test_that("autoplot.ebalance returns a ggplot when ggplot2 is available", {
  skip_if_not_installed("ggplot2")
  set.seed(20260504L)
  treatment <- c(rep(0, 50), rep(1, 30))
  X <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, 0.5)))
  colnames(X) <- paste0("x", 1:3)
  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)

  p <- ggplot2::autoplot(fit)
  expect_s3_class(p, "ggplot")
})

test_that("autoplot(trimmed, type = 'weights') and plot(trimmed, type = 'weights') work", {
  skip_if_not_installed("ggplot2")
  set.seed(20260505L)
  treatment <- c(rep(0, 50), rep(1, 30))
  X <- rbind(replicate(3, rnorm(50, 0)),
             replicate(3, rnorm(30, 0.5)))
  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)
  trimmed <- ebalance.trim(fit, max.weight = 5, print.level = 0)

  expect_s3_class(ggplot2::autoplot(trimmed, type = "weights"), "ggplot")
  expect_s3_class(ggplot2::autoplot(trimmed, type = "balance"), "ggplot")

  pdf(NULL); on.exit(dev.off(), add = TRUE)
  expect_silent(plot(trimmed, type = "weights"))
  expect_silent(plot(trimmed, type = "balance"))
})

test_that("autoplot(fit, type = 'weights') returns a ggplot for each estimand", {
  skip_if_not_installed("ggplot2")
  set.seed(20260504L)
  treatment <- c(rep(0, 50), rep(1, 30))
  X <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, 0.5)))
  colnames(X) <- paste0("x", 1:3)

  for (e in c("ATT", "ATE", "ATC")) {
    fit <- ebalance(Treatment = treatment, X = X, estimand = e,
                    print.level = 0)
    p <- ggplot2::autoplot(fit, type = "weights")
    expect_s3_class(p, "ggplot")
  }
})

test_that("plot(fit, type = 'weights') runs on each estimand without error", {
  set.seed(20260504L)
  treatment <- c(rep(0, 50), rep(1, 30))
  X <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, 0.5)))
  colnames(X) <- paste0("x", 1:3)

  pdf(NULL); on.exit(dev.off(), add = TRUE)
  for (e in c("ATT", "ATE", "ATC")) {
    fit <- ebalance(Treatment = treatment, X = X, estimand = e,
                    print.level = 0)
    expect_silent(plot(fit, type = "weights"))
  }
})

test_that("balance_table() returns the documented columns and an estimand attr", {
  set.seed(20260504L)
  treatment <- c(rep(0, 50), rep(1, 30))
  X <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, 0.5)))
  colnames(X) <- paste0("x", 1:3)
  fit <- ebalance(Treatment = treatment, X = X,
                  constraint.tolerance = 1e-10, print.level = 0)

  bt <- balance_table(fit)
  expect_named(bt, c("variable",
                     "mean_treated_pre", "mean_treated_post",
                     "mean_control_pre", "mean_control_post",
                     "diff_pre", "diff_post",
                     "std_diff_pre", "std_diff_post",
                     "pct_reduction"))
  expect_equal(attr(bt, "estimand"), "ATT")
  expect_equal(nrow(bt), ncol(X))
  # Treated means unchanged under ATT (treated weights are 1)
  expect_equal(bt$mean_treated_pre, bt$mean_treated_post, tolerance = 1e-12)
  # pct_reduction near 100 since post-weighting std_diff is essentially zero
  expect_true(all(bt$pct_reduction[!is.na(bt$pct_reduction)] > 99.9))
})
