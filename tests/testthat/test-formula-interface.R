test_that("formula and matrix interfaces give identical results", {
  set.seed(20260427L)
  treatment <- c(rep(0, 50), rep(1, 30))
  X <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, 0.5)))
  colnames(X) <- paste0("x", 1:3)
  df <- data.frame(treat = treatment, X)

  fit_mat <- ebalance(Treatment = treatment, X = X, print.level = 0)
  fit_for <- ebalance(treat ~ x1 + x2 + x3, data = df, print.level = 0)

  expect_s3_class(fit_for, "ebalance")
  expect_equal(fit_for$w, fit_mat$w, tolerance = 1e-12)
  expect_equal(fit_for$coefs, fit_mat$coefs, tolerance = 1e-12)
})

test_that("formula method requires data argument", {
  expect_error(ebalance(treat ~ x1, data = NULL), "'data' is required")
})

test_that("formula method rejects one-sided formula", {
  df <- data.frame(treat = c(0, 1), x1 = c(0, 1))
  expect_error(ebalance(~ x1, data = df))
})

test_that("formula method drops the intercept column from X", {
  set.seed(20260427L)
  df <- data.frame(
    treat = c(rep(0, 50), rep(1, 30)),
    x1 = rnorm(80), x2 = rnorm(80), x3 = rnorm(80)
  )
  fit <- ebalance(treat ~ x1 + x2 + x3, data = df, print.level = 0)
  # 1 (intercept moment) + 3 covariate moments = 4 target margins
  expect_length(fit$target.margins, 4L)
  expect_false("(Intercept)" %in% colnames(fit$X))
})
