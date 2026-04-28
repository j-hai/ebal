test_that("matrixmaker returns expected structure", {
  set.seed(7L)
  m <- matrix(rnorm(20), 5, 4)
  colnames(m) <- c("a", "b", "c", "d")

  out <- matrixmaker(m)
  k <- 4L
  expect_equal(ncol(out), k + (k * (k + 1)) / 2)
  expect_false("dummy" %in% colnames(out))
  expect_equal(out[, "a.a"], m[, "a"] * m[, "a"])
  expect_equal(out[, "c.b"], m[, "c"] * m[, "b"])
})

test_that("getsquares squares only non-binary columns", {
  set.seed(5L)
  m <- cbind(
    cont = rnorm(20),
    binary = sample(0:1, 20, TRUE),
    ternary = sample(1:3, 20, TRUE)
  )

  out <- getsquares(m)
  expect_equal(ncol(out), 5L)
  expect_true("cont.2" %in% colnames(out))
  expect_false("binary.2" %in% colnames(out))
  expect_true("ternary.2" %in% colnames(out))
})
