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

test_that("only for loops", {
  res <- gen_list(c(i, j, k), i = 1:10, j = 1:10, k = 1:5)
  expect_true(all(vapply(res, function(x) {
    x[1] %in% 1:10 && x[2] %in% 1:10 && x[3] %in% 1:5
  }, logical(1))))
})

test_that("only if", {
  res <- gen_list(42, 5 < 10)
  expect_equal(res, list(42))
  expect_error(gen_list(42, 5 > 10), "loop")
})

test_that("one can iterate in parallel", {
  res <- gen_list(c(i, j, k), list(i = 1:10, j = 1:10), k = 1:5)
  expect_equal(length(res), 10 * 5)
  for (i in 1:10) {
    for (k in 1:5) {
      expect_true(list(c(i, i, k)) %in% res)
    }
  }
})

test_that("parallel sequences can depend on iterators", {
  res <- gen_list(c(i, j, k), k = 1:5, list(i = k:10, j = k:10))
  expect_equal(length(res), 40)
  for (k in 1:5) {
    for (i in k:10) {
      expect_true(list(c(i, i, k)) %in% res)
    }
  }
})

test_that("initial expression can be very long", {
  res <- gen_list({
    1
    2
    3
    i
  }, i = 1:2)
  expect_equal(res, list(1, 2))
})

test_that("it works within a function", {
  test <- function(expr, ...) {
    expr <- rlang::enquo(expr)
    dots <- rlang::enquos(...)
    gen_list(!!expr, !!!dots)
  }
  limit <- 5
  res <- test(x, x = 1:10, x <= limit)
  expected <- gen_list(x, x = 1:10, x <= limit)
  expect_equal(res, expected)
})

#test_that("parallel lists need to have equal length", {
#  expect_error(
#    gen_list(c(i, j, k), list(i = 1:5, j = 1:10), k = 1:5), "length"
#  )
#})
