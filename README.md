
<!-- README.md is generated from README.Rmd. Please edit that file -->

# List comprehensions

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
<!-- badges: end -->

The package implements [list
comprehensions](https://en.wikipedia.org/wiki/List_comprehension) as
purely syntactic sugar with a minor runtime overhead. It constructs
nested for-loops and executes the byte-compiled loops to collect the
results.

**Experimental and WIP**

## Installation

``` r
remotes::install_github("dirkschumacher/complst")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(complst)
head(lst(c(x, y), x = 1:100, y = 1:100, z = 1:100, x < 5, y < 5, z == x + y))
#> [[1]]
#> [1] 1 1
#> 
#> [[2]]
#> [1] 1 2
#> 
#> [[3]]
#> [1] 1 3
#> 
#> [[4]]
#> [1] 1 4
#> 
#> [[5]]
#> [1] 2 1
#> 
#> [[6]]
#> [1] 2 2
```

``` r
lst(c(x, y), x = 1:10, y = x:5, x < 2)
#> [[1]]
#> [1] 1 1
#> 
#> [[2]]
#> [1] 1 2
#> 
#> [[3]]
#> [1] 1 3
#> 
#> [[4]]
#> [1] 1 4
#> 
#> [[5]]
#> [1] 1 5
```

This is how the code looks like:

``` r
lst_verbose <- function(expr, ...) {
  deparse(complst:::translate(rlang::enquo(expr), rlang::enquos(...)))
}
lst_verbose(c(x, y), x = 1:10, y = x:5, x < 2)
#>  [1] "{"                                                       
#>  [2] "    res <- new.env()"                                    
#>  [3] "    i_____ <- 1"                                         
#>  [4] "    iter_____x <- 1:10"                                  
#>  [5] "    for (x in iter_____x) {"                             
#>  [6] "        for (y in x:5) {"                                
#>  [7] "            {"                                           
#>  [8] "                if (!(x < 2)) {"                         
#>  [9] "                  next"                                  
#> [10] "                }"                                       
#> [11] "                {"                                       
#> [12] "                  res[[as.character(i_____)]] <- c(x, y)"
#> [13] "                  i_____ <- i_____ + 1"                  
#> [14] "                }"                                       
#> [15] "            }"                                           
#> [16] "        }"                                               
#> [17] "    }"                                                   
#> [18] "    res <- as.list(res, sorted = FALSE)"                 
#> [19] "    res <- res[order(as.numeric(names(res)))]"           
#> [20] "    names(res) <- NULL"                                  
#> [21] "    res"                                                 
#> [22] "}"
```

You can also burn in external variables

``` r
z <- 10
lst(c(x, y), x = 1:!!z, y = x:5, x < 2)
#> [[1]]
#> [1] 1 1
#> 
#> [[2]]
#> [1] 1 2
#> 
#> [[3]]
#> [1] 1 3
#> 
#> [[4]]
#> [1] 1 4
#> 
#> [[5]]
#> [1] 1 5
```

It is quite fast, but the order of filter conditions also greatly
determines the execution time. Sometimes, ahead of time compiling is
slower than running it right away.

``` r
bench::mark(
  a = lst(c(x, y), x = 1:100, y = 1:100, z = 1:100, x < 5, y < 5, z == x + y),
  b = lst(c(x, y), x = 1:100, x < 5, y = 1:100, y < 5, z = 1:100, z == x + y),
  c = lst(c(x, y), x = 1:100, y = 1:100, z = 1:100, x < 5, y < 5, z == x + y, .compile = FALSE),
  d = lst(c(x, y), x = 1:100, x < 5, y = 1:100, y < 5, z = 1:100, z == x + y, .compile = FALSE)
)
#> Warning: Some expressions had a GC in every iteration; so filtering is
#> disabled.
#> # A tibble: 4 x 6
#>   expression      min   median `itr/sec` mem_alloc `gc/sec`
#>   <bch:expr> <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
#> 1 a           42.33ms  46.01ms     21.3      142KB     5.81
#> 2 b           14.29ms  17.02ms     54.9      142KB    11.8 
#> 3 c          839.06ms 839.06ms      1.19      280B     8.34
#> 4 d            2.44ms   2.87ms    278.        280B     7.95
```

How slow is it compared to a for loop and lapply?

``` r
bench::mark(
  a = lst(x * 2, x = 1:1000, x**2 < 100),
  b = lst(x * 2, x = 1:1000, x**2 < 100, .compile = FALSE),
  c = lapply(Filter(function(x) x**2 < 100, 1:1000), function(x) x * 2),
  d = {
    res <- list()
    for (x in 1:1000) {
      if (x**2 >= 100) next
      res[[length(res) + 1]] <- x * 2
    }
    res
  }, 
  time_unit = "ms"
)
#> # A tibble: 4 x 6
#>   expression   min median `itr/sec` mem_alloc `gc/sec`
#>   <bch:expr> <dbl>  <dbl>     <dbl> <bch:byt>    <dbl>
#> 1 a          8.66   9.81       73.9    86.6KB    13.2 
#> 2 b          1.34   1.61      480.       280B     8.81
#> 3 c          0.522  0.595    1282.     88.1KB    17.7 
#> 4 d          3.24   3.44      253.     42.6KB    16.0
```
