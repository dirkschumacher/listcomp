
<!-- README.md is generated from README.Rmd. Please edit that file -->

# List comprehensions

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![R build
status](https://github.com/dirkschumacher/listcomp/workflows/R-CMD-check/badge.svg)](https://github.com/dirkschumacher/listcomp/actions)
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
#>  [6] "        for (iter_44e1d1cb0c49a3f735dc3c677be82a1f in seq_along(parallel_seq[[1]])) {"
#>  [7] "            i <- parallel_seq[[\"i\"]][[iter_44e1d1cb0c49a3f735dc3c677be82a1f]]"      
#>  [8] "            j <- parallel_seq[[\"j\"]][[iter_44e1d1cb0c49a3f735dc3c677be82a1f]]"      
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
#> 1 a           45.09ms  58.41ms     15.8      112KB     1.97
#> 2 b           12.35ms  14.62ms     60.3      112KB    11.7 
#> 3 c          768.57ms 768.57ms      1.30      280B     9.11
#> 4 d            1.93ms   2.28ms    392.        280B    10.0
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
#> 1 a          6.37   7.77       124.    56.7KB     14.1
#> 2 b          1.04   1.18       768.      280B     13.2
#> 3 c          0.792  0.918     1034.    15.8KB     29.5
#> 4 d          0.437  0.489     1731.        0B     19.6
```

# Prior art

  - [lc](https://github.com/mailund/lc) Uses a similiar syntax as
    `complist`
  - [comprehenr](https://github.com/gdemin/comprehenr) Uses a similiar
    code generation approach as `complist` but with a different syntax.
