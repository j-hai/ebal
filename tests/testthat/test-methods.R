test_that("weights() returns a length-n vector aligned to Treatment", {
  set.seed(20260427L)
  treatment <- c(rep(0, 50), rep(1, 30))
  X <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, 0.5)))
  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)

  w <- weights(fit)
  expect_length(w, 80L)
  expect_true(all(w[treatment == 1] == 1))
  expect_equal(w[treatment == 0], fit$w, tolerance = 1e-15)
})

test_that("weights() works on ebalance.trim objects", {
  set.seed(20260427L)
  treatment <- c(rep(0, 50), rep(1, 30))
  X <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, 0.5)))
  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)
  trimmed <- ebalance.trim(fit, print.level = 0)

  w <- weights(trimmed)
  expect_length(w, 80L)
  expect_true(all(w[treatment == 1] == 1))
})

test_that("print.ebalance shows expected fields", {
  set.seed(20260427L)
  treatment <- c(rep(0, 50), rep(1, 30))
  X <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, 0.5)))
  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)

  out <- capture.output(print(fit))
  expect_true(any(grepl("Entropy balancing", out)))
  expect_true(any(grepl("Treated:", out)))
  expect_true(any(grepl("Converged:", out)))
})

test_that("summary.ebalance returns balance table with expected columns", {
  set.seed(20260427L)
  treatment <- c(rep(0, 50), rep(1, 30))
  X <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, 0.5)))
  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)

  s <- summary(fit)
  expect_s3_class(s, "summary.ebalance")
  expect_s3_class(s$balance, "data.frame")
  expected_cols <- c("mean.Tr", "mean.Co.pre", "mean.Co.post",
                     "diff.pre", "diff.post",
                     "std.diff.pre", "std.diff.post")
  expect_true(all(expected_cols %in% colnames(s$balance)))
  # post-weighting standardized differences should be near zero
  expect_true(all(abs(s$balance$std.diff.post) < 0.05))
})

test_that("summary.ebalance.trim includes trim.feasible", {
  set.seed(20260427L)
  treatment <- c(rep(0, 50), rep(1, 30))
  X <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, 0.5)))
  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)
  trimmed <- ebalance.trim(fit, print.level = 0)

  s <- summary(trimmed)
  expect_s3_class(s, "summary.ebalance.trim")
  expect_false(is.null(s$call.info$trim.feasible))
})

test_that("plot.ebalance writes a non-empty PDF", {
  skip_on_cran()  # plotting may be flaky on minimal CRAN setups
  set.seed(20260427L)
  treatment <- c(rep(0, 50), rep(1, 30))
  X <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, 0.5)))
  fit <- ebalance(Treatment = treatment, X = X, print.level = 0)

  pdf_path <- tempfile(fileext = ".pdf")
  pdf(pdf_path)
  expect_no_error(plot(fit))
  dev.off()
  expect_true(file.exists(pdf_path))
  expect_gt(file.size(pdf_path), 0)
  unlink(pdf_path)
})
