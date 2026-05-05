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
