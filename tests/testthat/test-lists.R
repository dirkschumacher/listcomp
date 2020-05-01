test_that("simple stuff works", {
  res <- gen_list(c(i, j), i = 1:10, j = 1:10, i < j)
  expect_true(all(vapply(res, function(x) x[1] < x[2], logical(1))))
})

test_that("tidy eval works", {
  x <- 10
  res <- gen_list(c(i, j), i = 1:!!x, j = 1:10, i < j)
  expect_true(all(vapply(res, function(x) x[1] < x[2], logical(1))))
})

test_that("comile works", {
  res1 <- gen_list(c(i, j), i = 1:10, j = 1:10, i < j)
  res2 <- gen_list(c(i, j), i = 1:10, j = 1:10, i < j, .compile = FALSE)
  expect_equal(
    res1,
    res2
  )
})

test_that("dependent loop variables work", {
  res <- gen_list(c(i, j), i = 1:10, j = i:10, i + j == 6)
  expect_true(all(vapply(res, function(x) {
    x[2] >= x[1] && x[1] + x[2] == 6
  }, logical(1))))
})
