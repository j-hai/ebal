# Regression tests for the input-validation bugs from the 0.3-0 code
# review: NAs in Treatment / X / formula data, and bad base.weight.

.toy <- function() {
  set.seed(20260504L)
  X <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, 0.5)))
  colnames(X) <- paste0("x", 1:3)
  list(
    treatment = c(rep(0, 50), rep(1, 30)),
    X = X
  )
}

test_that("NA in Treatment hits the NA check, not the binary check", {
  d <- .toy()
  d$treatment[1] <- NA
  expect_error(ebalance(Treatment = d$treatment, X = d$X),
               "Treatment contains missing data")
})

test_that("NA in X hits the NA check before length check", {
  d <- .toy()
  d$X[1, 1] <- NA
  expect_error(ebalance(Treatment = d$treatment, X = d$X),
               "X contains missing data")
})

test_that("formula NA in covariate is rejected with a clear message", {
  d <- .toy()
  df <- data.frame(treat = d$treatment, d$X)
  df$x1[1] <- NA
  expect_error(ebalance(treat ~ x1 + x2 + x3, data = df),
               "missing data")  # matches both "X contains missing data"
                                # and "Treatment contains missing data"
})

test_that("formula NA in response is rejected with a clear message", {
  d <- .toy()
  df <- data.frame(treat = d$treatment, d$X)
  df$treat[1] <- NA
  expect_error(ebalance(treat ~ x1 + x2 + x3, data = df),
               "Treatment contains missing data")
})

test_that("weak-fit warning fires (and is suppressible) on a low-ESS fit", {
  set.seed(20260505L)
  treatment <- c(rep(0, 50), rep(1, 30))
  X <- rbind(replicate(3, rnorm(50, 0)),
             replicate(3, rnorm(30, 0.5)))

  # Test the warning path indirectly by calling .warn_weak_fit() with
  # a high ess_warn that forces the threshold to fire on this fixture.
  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)
  withr::with_options(list(ebal.warn_weak_fit = TRUE), {
    expect_warning(
      ebal:::.warn_weak_fit(fit, ess_warn = 0.99),
      "concentrated on a small number"
    )
  })
  # And opting out suppresses it.
  withr::with_options(list(ebal.warn_weak_fit = FALSE), {
    expect_no_warning(ebal:::.warn_weak_fit(fit, ess_warn = 0.99))
  })
})

test_that("weak-fit warning fires loudly when convergence fails", {
  # Force non-convergence by capping iterations very low. The fit still
  # returns; the .warn_weak_fit() helper should flag it.
  set.seed(20260505L)
  treatment <- c(rep(0, 50), rep(1, 30))
  X <- rbind(replicate(3, rnorm(50, 0)),
             replicate(3, rnorm(30, 1.0)))
  withr::with_options(list(ebal.warn_weak_fit = TRUE), {
    expect_warning(
      ebalance(Treatment = treatment, X = X,
               max.iterations = 1, print.level = 0),
      "did not converge"
    )
  })
})

test_that("diagnostics() returns a structured object and prints PASS/WARN/FAIL", {
  set.seed(20260505L)
  treatment <- c(rep(0, 50), rep(1, 30))
  X <- rbind(replicate(3, rnorm(50, 0)),
             replicate(3, rnorm(30, 0.5)))
  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)
  d <- diagnostics(fit)
  expect_s3_class(d, "ebalance.diagnostics")
  expect_equal(d$estimand, "ATT")
  expect_true(d$check_balance$status %in% c("PASS", "WARN", "FAIL"))
  out <- capture.output(print(d))
  expect_true(any(grepl("PASS|WARN|FAIL", out)))
})

test_that("norm.constant rejects 0, NA, Inf, negative for ATT/ATC", {
  d <- .toy()
  for (bad in list(0, NA_real_, Inf, -1)) {
    expect_error(
      ebalance(Treatment = d$treatment, X = d$X, norm.constant = bad),
      "finite positive scalar"
    )
    expect_error(
      ebalance(Treatment = d$treatment, X = d$X,
               norm.constant = bad, estimand = "ATC"),
      "finite positive scalar"
    )
  }
  expect_error(
    ebalance(Treatment = d$treatment, X = d$X,
             norm.constant = c(1, 2)),
    "finite positive scalar"
  )
})

test_that("max.iterations and constraint.tolerance are validated", {
  d <- .toy()
  expect_error(ebalance(Treatment = d$treatment, X = d$X,
                        max.iterations = 0),
               "finite positive scalar")
  expect_error(ebalance(Treatment = d$treatment, X = d$X,
                        max.iterations = -1),
               "finite positive scalar")
  expect_error(ebalance(Treatment = d$treatment, X = d$X,
                        max.iterations = NA),
               "finite positive scalar")
  expect_error(ebalance(Treatment = d$treatment, X = d$X,
                        constraint.tolerance = 0),
               "finite positive scalar")
  expect_error(ebalance(Treatment = d$treatment, X = d$X,
                        constraint.tolerance = NA),
               "finite positive scalar")
  expect_error(ebalance(Treatment = d$treatment, X = d$X,
                        constraint.tolerance = -0.1),
               "finite positive scalar")
})

test_that("base.weight rejects NA / Inf / negatives / zero sum", {
  d <- .toy()
  bw <- rep(1, 50)
  bw[1] <- NA
  expect_error(ebalance(Treatment = d$treatment, X = d$X, base.weight = bw),
               "finite")
  bw <- rep(1, 50); bw[1] <- Inf
  expect_error(ebalance(Treatment = d$treatment, X = d$X, base.weight = bw),
               "finite")
  bw <- rep(1, 50); bw[1] <- -1
  expect_error(ebalance(Treatment = d$treatment, X = d$X, base.weight = bw),
               "non-negative")
  bw <- rep(0, 50)
  expect_error(ebalance(Treatment = d$treatment, X = d$X, base.weight = bw),
               "positive sum")
})
