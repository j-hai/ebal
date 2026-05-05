.toy_estimand <- function() {
  set.seed(20260504L)
  n0 <- 60; n1 <- 40
  X <- rbind(replicate(3, rnorm(n0, mean = 0)),
             replicate(3, rnorm(n1, mean = 0.6)))
  colnames(X) <- paste0("x", 1:3)
  list(treatment = c(rep(0, n0), rep(1, n1)), X = X)
}

# Use a tight constraint.tolerance so the moment match is precise
# enough to test against numerical equality.
.fit_e <- function(d, estimand) {
  ebalance(Treatment = d$treatment, X = d$X, estimand = estimand,
           constraint.tolerance = 1e-8, print.level = 0)
}

test_that("ATT (default) reweights controls to match treated", {
  d <- .toy_estimand()
  fit <- .fit_e(d, "ATT")
  expect_equal(fit$estimand, "ATT")
  expect_true(fit$converged)
  w <- weights(fit)
  expect_length(w, length(d$treatment))
  expect_true(all(w[d$treatment == 1] == 1))
  expect_equal(w[d$treatment == 0], fit$w)
  for (j in seq_len(ncol(d$X))) {
    expect_equal(unname(weighted.mean(d$X[d$treatment == 0, j], w = fit$w)),
                 unname(mean(d$X[d$treatment == 1, j])),
                 tolerance = 1e-6)
  }
})

test_that("ATC reweights treated to match controls (symmetric to ATT)", {
  d <- .toy_estimand()
  fit <- .fit_e(d, "ATC")
  expect_equal(fit$estimand, "ATC")
  expect_true(fit$converged)
  w <- weights(fit)
  expect_length(w, length(d$treatment))
  expect_true(all(w[d$treatment == 0] == 1))
  expect_equal(w[d$treatment == 1], fit$w)
  for (j in seq_len(ncol(d$X))) {
    expect_equal(unname(weighted.mean(d$X[d$treatment == 1, j], w = fit$w)),
                 unname(mean(d$X[d$treatment == 0, j])),
                 tolerance = 1e-6)
  }
})

test_that("ATE reweights both groups to overall sample moments", {
  d <- .toy_estimand()
  fit <- .fit_e(d, "ATE")
  expect_equal(fit$estimand, "ATE")
  expect_true(fit$converged)
  expect_true(!is.null(fit$control_solve))
  expect_true(!is.null(fit$treated_solve))
  overall <- unname(colMeans(d$X))
  for (j in seq_len(ncol(d$X))) {
    expect_equal(unname(weighted.mean(d$X[d$treatment == 0, j],
                                      w = fit$control_solve$w)),
                 overall[j], tolerance = 1e-6)
    expect_equal(unname(weighted.mean(d$X[d$treatment == 1, j],
                                      w = fit$treated_solve$w)),
                 overall[j], tolerance = 1e-6)
  }
  w <- weights(fit)
  expect_equal(w[d$treatment == 0], fit$control_solve$w)
  expect_equal(w[d$treatment == 1], fit$treated_solve$w)
})

test_that("glance() reports the estimand", {
  d <- .toy_estimand()
  expect_equal(generics::glance(.fit_e(d, "ATT"))$estimand, "ATT")
  expect_equal(generics::glance(.fit_e(d, "ATC"))$estimand, "ATC")
  expect_equal(generics::glance(.fit_e(d, "ATE"))$estimand, "ATE")
})

test_that("ATE accepts list(treated=, control=) for base.weight", {
  d <- .toy_estimand()
  bw_ctrl <- runif(60, 0.5, 1.5)
  bw_trt  <- runif(40, 0.5, 1.5)
  fit <- ebalance(Treatment = d$treatment, X = d$X, estimand = "ATE",
                  base.weight = list(control = bw_ctrl, treated = bw_trt),
                  constraint.tolerance = 1e-6, print.level = 0)
  expect_true(fit$converged)
})

test_that("ebalance.trim refuses to operate on ATE objects", {
  d <- .toy_estimand()
  fit_ate <- .fit_e(d, "ATE")
  expect_error(ebalance.trim(fit_ate), "ATE")
})
