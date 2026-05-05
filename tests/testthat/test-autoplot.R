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
