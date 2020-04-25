test_that("simple stuff works", {
  res <- lst(c(i, j), i = 1:10, j = 1:10, i < j)
  expect_true(all(vapply(res, function(x) x[1] < x[2], logical(1))))
})

test_that("tidy eval works", {
  x <- 10
  res <- lst(c(i, j), i = 1:!!x, j = 1:10, i < j)
  expect_true(all(vapply(res, function(x) x[1] < x[2], logical(1))))
})

