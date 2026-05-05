test_that("method = 'autodiff' produces weights equivalent to Newton on a toy", {
  skip_if_not_installed("torch")
  skip_if_not(torch::torch_is_installed(),
              "libtorch not installed; run torch::install_torch()")

  set.seed(20260504L)
  treatment <- c(rep(0, 50), rep(1, 30))
  X <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, 0.5)))
  colnames(X) <- paste0("x", 1:3)

  fit_n  <- ebalance(Treatment = treatment, X = X,
                     method = "newton",   print.level = 0)
  fit_ad <- ebalance(Treatment = treatment, X = X,
                     method = "autodiff", print.level = 0)

  expect_s3_class(fit_n,  "ebalance")
  expect_s3_class(fit_ad, "ebalance")
  expect_true(fit_n$converged)
  expect_true(fit_ad$converged)

  # Weights agree to within solver tolerance. Newton is essentially
  # exact (1e-8 default); BFGS-on-autograd typically agrees to ~1e-2.
  # The actually-meaningful test below is that the post-weighting
  # balance is achieved — that's what matters for users.
  expect_equal(as.numeric(fit_ad$w), as.numeric(fit_n$w),
               tolerance = 5e-2)

  # Post-weighting control means match treated means under autodiff.
  # This is the constraint the dual is solving; agreement here is the
  # real test of correctness.
  for (j in seq_len(ncol(X))) {
    expect_equal(weighted.mean(X[treatment == 0, j], w = fit_ad$w),
                 mean(X[treatment == 1, j]),
                 tolerance = 1e-3)
  }
})

test_that("autodiff fit$coefs reconstructs fit$w via base.weight * exp(co.x %*% coefs)", {
  skip_if_not_installed("torch")
  skip_if_not(torch::torch_is_installed(),
              "libtorch not installed; run torch::install_torch()")

  set.seed(20260504L)
  treatment <- c(rep(0, 50), rep(1, 30))
  X <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, 0.5)))
  colnames(X) <- paste0("x", 1:3)
  fit <- ebalance(Treatment = treatment, X = X,
                  method = "autodiff", print.level = 0)

  # The eb() output convention is fit$w = base.weight * exp(co.xdata %*% fit$coefs)
  reconstructed <- as.numeric(fit$base.weight *
                              exp(fit$co.xdata %*% fit$coefs))
  expect_equal(reconstructed, as.numeric(fit$w), tolerance = 1e-6)
  # And the implied weights sum to norm.constant (default = ntreated)
  expect_equal(sum(reconstructed), sum(treatment == 1), tolerance = 1e-6)
})

test_that("method = 'autodiff' errors gracefully when torch is unavailable", {
  skip_if(requireNamespace("torch", quietly = TRUE),
          "torch is installed; this test only runs when it is missing")
  set.seed(20260504L)
  treatment <- c(rep(0, 50), rep(1, 30))
  X <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, 0.5)))
  colnames(X) <- paste0("x", 1:3)
  expect_error(
    ebalance(Treatment = treatment, X = X,
             method = "autodiff", print.level = 0),
    "torch is not installed"
  )
})
