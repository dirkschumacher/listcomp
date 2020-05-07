
<!-- README.md is generated from README.Rmd. Please edit that file -->

# List comprehensions

<!-- badges: start -->

[![R build
status](https://github.com/dirkschumacher/listcomp/workflows/R-CMD-check/badge.svg)](https://github.com/dirkschumacher/listcomp/actions)
[![Lifecycle:
maturing](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://www.tidyverse.org/lifecycle/#maturing)
[![CRAN
status](https://www.r-pkg.org/badges/version/listcomp)](https://CRAN.R-project.org/package=listcomp)
<!-- badges: end -->

The package implements [list
comprehensions](https://en.wikipedia.org/wiki/List_comprehension) as
purely syntactic sugar with a minor runtime overhead. It constructs
nested for-loops and executes the byte-compiled loops to collect the
results.

## Installation

``` r
remotes::install_github("dirkschumacher/listcomp")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(listcomp)
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
  deparse(listcomp:::translate(rlang::enquo(expr), rlang::enquos(...)))
}
lst_verbose(c(x, y), x = 1:10, y = x:5, x < 2)
#>  [1] "{"                                                  
#>  [2] "    res_____ <- list()"                             
#>  [3] "    iter_____x <- 1:10"                             
#>  [4] "    for (x in iter_____x) for (y in x:5) {"         
#>  [5] "        if (!(x < 2)) {"                            
#>  [6] "            next"                                   
#>  [7] "        }"                                          
#>  [8] "        res_____[[length(res_____) + 1]] <- c(x, y)"
#>  [9] "    }"                                              
#> [10] "    res_____"                                       
#> [11] "}"
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

It also supports parallel iteration by passing a list of named sequences

``` r
gen_list(c(i, j, k), list(i = 1:10, j = 1:10), k = 1:5, i < 3, k < 3)
#> [[1]]
#> [1] 1 1 1
#> 
#> [[2]]
#> [1] 1 1 2
#> 
#> [[3]]
#> [1] 2 2 1
#> 
#> [[4]]
#> [1] 2 2 2
```

The code then looks like this:

``` r
lst_verbose(c(i, j, k), list(i = 1:10, j = 1:10), k = 1:5, i < 3, k < 3)
#>  [1] "{"                                                                                    
#>  [2] "    res_____ <- list()"                                                               
#>  [3] "    iter_____k <- 1:5"                                                                
#>  [4] "    {"                                                                                
#>  [5] "        parallel_seq <- list(i = 1:10, j = 1:10)"                                     
#>  [6] "        for (iter_8ed0a342ff54a1de160edcce7ebea3d0 in seq_along(parallel_seq[[1]])) {"
#>  [7] "            i <- parallel_seq[[\"i\"]][[iter_8ed0a342ff54a1de160edcce7ebea3d0]]"      
#>  [8] "            j <- parallel_seq[[\"j\"]][[iter_8ed0a342ff54a1de160edcce7ebea3d0]]"      
#>  [9] "            for (k in iter_____k) {"                                                  
#> [10] "                if (!(i < 3)) {"                                                      
#> [11] "                  next"                                                               
#> [12] "                }"                                                                    
#> [13] "                {"                                                                    
#> [14] "                  if (!(k < 3)) {"                                                    
#> [15] "                    next"                                                             
#> [16] "                  }"                                                                  
#> [17] "                  res_____[[length(res_____) + 1]] <- c(i, j, "                       
#> [18] "                    k)"                                                               
#> [19] "                }"                                                                    
#> [20] "            }"                                                                        
#> [21] "        }"                                                                            
#> [22] "    }"                                                                                
#> [23] "    res_____"                                                                         
#> [24] "}"
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
#> Warning: Some expressions had a GC in every iteration; so filtering is disabled.
#> # A tibble: 4 x 6
#>   expression      min   median `itr/sec` mem_alloc `gc/sec`
#>   <bch:expr> <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
#> 1 a           39.91ms  41.44ms     23.2      112KB     3.86
#> 2 b           12.16ms   13.3ms     70.4      112KB    13.7 
#> 3 c          605.74ms 605.74ms      1.65      280B    11.6 
#> 4 d            1.89ms   2.08ms    420.        280B    12.0
```

How slow is it compared to a for loop and lapply for a very simple
example?

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
#>   expression   min median `itr/sec` mem_alloc `gc/sec`
#>   <bch:expr> <dbl>  <dbl>     <dbl> <bch:byt>    <dbl>
#> 1 a          6.48   7.82       125.    56.7KB     14.4
#> 2 b          1.02   1.18       720.      280B     12.9
#> 3 c          0.799  0.884      941.    15.8KB     24.9
#> 4 d          0.434  0.468     1900.        0B     22.0
```

# Prior art

  - [lc](https://github.com/mailund/lc) Uses a similiar syntax as
    `complist`
  - [comprehenr](https://github.com/gdemin/comprehenr) Uses a similiar
    code generation approach as `complist` but with a different syntax.
