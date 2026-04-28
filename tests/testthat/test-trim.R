test_that("ebalance.trim auto-minimization succeeds", {
  set.seed(20260427L)
  treatment <- c(rep(0, 100), rep(1, 50))
  X <- rbind(replicate(3, rnorm(100, 0)),
             replicate(3, rnorm(50, 0.6)))
  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)

  trimmed <- ebalance.trim(fit, print.level = 0)
  expect_s3_class(trimmed, "ebalance.trim")
  expect_true(trimmed$trim.feasible)
  expect_true(trimmed$converged)
  # auto mode reduces max weight ratio compared to untrimmed fit
  expect_lt(max(trimmed$w / mean(trimmed$w)),
            max(fit$w / mean(fit$w)) + 1e-6)
})

test_that("ebalance.trim with achievable target meets it and reports feasible", {
  set.seed(20260427L)
  treatment <- c(rep(0, 100), rep(1, 50))
  X <- rbind(replicate(3, rnorm(100, 0)),
             replicate(3, rnorm(50, 0.6)))
  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)
  base.ratio <- max(fit$w / mean(fit$w))
  target <- base.ratio * 1.5

  trimmed <- ebalance.trim(fit, max.weight = target, print.level = 0)
  expect_true(trimmed$trim.feasible)
  expect_lte(max(trimmed$w / mean(trimmed$w)), target)
})

test_that("ebalance.trim with infeasible target falls back gracefully", {
  set.seed(20260427L)
  treatment <- c(rep(0, 100), rep(1, 50))
  X <- rbind(replicate(3, rnorm(100, 0)),
             replicate(3, rnorm(50, 0.6)))
  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)

  expect_warning(
    trimmed <- ebalance.trim(fit, max.weight = 3, print.level = 0),
    "Trimming halted"
  )
  expect_s3_class(trimmed, "ebalance.trim")
  expect_false(trimmed$trim.feasible)
  expect_true(all(is.finite(trimmed$w)))
})

test_that("ebalance.trim populates target.margins (regression test for 0.1-8 bug)", {
  set.seed(20260427L)
  treatment <- c(rep(0, 100), rep(1, 50))
  X <- rbind(replicate(3, rnorm(100, 0)),
             replicate(3, rnorm(50, 0.6)))
  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)

  trimmed <- ebalance.trim(fit, print.level = 0)
  expect_false(is.null(trimmed$target.margins))
  expect_identical(trimmed$target.margins, fit$target.margins)
})

test_that("ebalance.trim rejects non-ebalance input", {
  expect_error(ebalance.trim(list(a = 1)), "ebalance object")
})
