test_that("ebalance() with matrix interface converges on a simple toy", {
  set.seed(20260427L)
  treatment <- c(rep(0, 50), rep(1, 30))
  X <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, 0.5)))
  colnames(X) <- paste0("x", 1:3)

  fit <- ebalance(Treatment = treatment, X = X,
                  constraint.tolerance = 1e-8, print.level = 0)

  expect_s3_class(fit, "ebalance")
  expect_true(fit$converged)
  expect_length(fit$w, 50L)
  # post-weighting control means match treated means up to the
  # solver tolerance scaled by 1/ntreated
  ntreated <- sum(treatment == 1)
  for (j in seq_len(ncol(X))) {
    expect_equal(weighted.mean(X[treatment == 0, j], w = fit$w),
                 mean(X[treatment == 1, j]),
                 tolerance = 1e-8 / ntreated * 10)  # generous slack
  }
})

test_that("ebalance() handles a single covariate without dim drop", {
  set.seed(20260427L)
  treatment <- c(rep(0, 60), rep(1, 40))
  X <- matrix(c(rnorm(60), rnorm(40, 0.7)), ncol = 1,
              dimnames = list(NULL, "x1"))

  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)
  expect_true(fit$converged)
  expect_length(fit$w, 60L)
})

test_that("ebalance() supports non-uniform base.weight", {
  set.seed(20260427L)
  treatment <- c(rep(0, 80), rep(1, 40))
  X <- rbind(replicate(4, rnorm(80, 0)), replicate(4, rnorm(40, 0.4)))
  ncontrols <- sum(treatment == 0)
  bw <- runif(ncontrols, 0.5, 1.5)

  fit <- ebalance(Treatment = treatment, X = X, base.weight = bw,
                  print.level = 0)
  expect_true(fit$converged)
})

test_that("ebalance() rejects malformed inputs with clear messages", {
  X <- matrix(rnorm(20), 10, 2)
  treatment <- c(rep(0, 5), rep(1, 5))

  expect_error(ebalance(Treatment = c(0, 0, 0, 2), X = X[1:4, ]),
               "logical")
  expect_error(ebalance(Treatment = rep(0, 10), X = X),
               "treatment and control")
  bad_X <- X
  bad_X[1, 1] <- NA
  expect_error(ebalance(Treatment = treatment, X = bad_X),
               "missing data")
})
