
<!-- README.md is generated from README.Rmd. Please edit that file -->

# List comprehensions

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![R build
status](https://github.com/dirkschumacher/complst/workflows/R-CMD-check/badge.svg)](https://github.com/dirkschumacher/complst/actions)
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
head(gen_list(c(x, y), x = 1:100, y = 1:100, z = 1:100, x < 5, y < 5, z == x + y))
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
gen_list(c(x, y), x = 1:10, y = x:5, x < 2)
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
#>  [2] "    res <- fastmap::fastmap()"                           
#>  [3] "    i_____ <- 1"                                         
#>  [4] "    iter_____x <- 1:10"                                  
#>  [5] "    for (x in iter_____x) {"                             
#>  [6] "        for (y in x:5) {"                                
#>  [7] "            {"                                           
#>  [8] "                if (!(x < 2)) {"                         
#>  [9] "                  next"                                  
#> [10] "                }"                                       
#> [11] "                {"                                       
#> [12] "                  res$set(as.character(i_____), c(x, y))"
#> [13] "                  i_____ <- i_____ + 1"                  
#> [14] "                }"                                       
#> [15] "            }"                                           
#> [16] "        }"                                               
#> [17] "    }"                                                   
#> [18] "    res <- res$as_list(sort = FALSE)"                    
#> [19] "    res <- res[order(as.numeric(names(res)))]"           
#> [20] "    names(res) <- NULL"                                  
#> [21] "    res"                                                 
#> [22] "}"
```

You can also burn in external variables

``` r
z <- 10
gen_list(c(x, y), x = 1:!!z, y = x:5, x < 2)
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
  a = gen_list(c(x, y), x = 1:100, y = 1:100, z = 1:100, x < 5, y < 5, z == x + y),
  b = gen_list(c(x, y), x = 1:100, x < 5, y = 1:100, y < 5, z = 1:100, z == x + y),
  c = gen_list(c(x, y), x = 1:100, y = 1:100, z = 1:100, x < 5, y < 5, z == x + y, .compile = FALSE),
  d = gen_list(c(x, y), x = 1:100, x < 5, y = 1:100, y < 5, z = 1:100, z == x + y, .compile = FALSE)
)
#> Warning: Some expressions had a GC in every iteration; so filtering is
#> disabled.
#> # A tibble: 4 x 6
#>   expression      min   median `itr/sec` mem_alloc `gc/sec`
#>   <bch:expr> <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
#> 1 a           68.33ms  87.74ms    10.7       139KB     1.78
#> 2 b           17.46ms  38.33ms    23.4       139KB     3.60
#> 3 c             1.62s    1.62s     0.616      888B     4.31
#> 4 d            2.27ms   5.55ms   154.         888B     3.95
```

How slow is it compared to a for loop and lapply?

``` r
bench::mark(
  a = gen_list(x * 2, x = 1:1000, x**2 < 100),
  b = gen_list(x * 2, x = 1:1000, x**2 < 100, .compile = FALSE),
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
#>   expression    min median `itr/sec` mem_alloc `gc/sec`
#>   <bch:expr>  <dbl>  <dbl>     <dbl> <bch:byt>    <dbl>
#> 1 a          10.3   20.9        44.0      79KB     6.94
#> 2 b           1.38   2.57      327.       888B     6.37
#> 3 c           0.544  0.810     986.     88.1KB    13.3 
#> 4 d           3.34   6.30      116.    124.2KB     7.09
```

# Prior art

  - [lc](https://github.com/mailund/lc)
  - [comprehenr](https://github.com/gdemin/comprehenr)
