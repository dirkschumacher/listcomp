
<!-- README.md is generated from README.Rmd. Please edit that file -->

# List comprehensions

<!-- badges: start -->

[![R build
status](https://github.com/dirkschumacher/listcomp/workflows/R-CMD-check/badge.svg)](https://github.com/dirkschumacher/listcomp/actions)
[![CRAN
status](https://www.r-pkg.org/badges/version/listcomp)](https://CRAN.R-project.org/package=listcomp)
[![R-CMD-check](https://github.com/dirkschumacher/listcomp/workflows/R-CMD-check/badge.svg)](https://github.com/dirkschumacher/listcomp/actions)
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

``` r
install.packages("listcomp")
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
#>  [2] "    var_listcomp____49b14e0356b0eb75890f57cdba263f2c <- list()"                                                       
#>  [3] "    var_listcomp____e914ec62bcf06fa4923666b0cb589de7 <- 1:10"                                                         
#>  [4] "    for (x in var_listcomp____e914ec62bcf06fa4923666b0cb589de7) for (y in x:5) {"                                     
#>  [5] "        if (!(x < 2)) {"                                                                                              
#>  [6] "            next"                                                                                                     
#>  [7] "        }"                                                                                                            
#>  [8] "        var_listcomp____49b14e0356b0eb75890f57cdba263f2c[[length(var_listcomp____49b14e0356b0eb75890f57cdba263f2c) + "
#>  [9] "            1]] <- c(x, y)"                                                                                           
#> [10] "    }"                                                                                                                
#> [11] "    var_listcomp____49b14e0356b0eb75890f57cdba263f2c"                                                                 
#> [12] "}"
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
#>  [2] "    var_listcomp____0cc901998ffca8eb9ab6e66438eabb65 <- list()"                                                                 
#>  [3] "    var_listcomp____edc8004e1fc9172689566a16fc4a2cf6 <- 1:5"                                                                    
#>  [4] "    {"                                                                                                                          
#>  [5] "        parallel_seq <- list(i = 1:10, j = 1:10)"                                                                               
#>  [6] "        for (var_listcomp____b1394f1020f630cb5b96890e815444b7 in seq_along(parallel_seq[[1]])) {"                               
#>  [7] "            i <- parallel_seq[[\"i\"]][[var_listcomp____b1394f1020f630cb5b96890e815444b7]]"                                     
#>  [8] "            j <- parallel_seq[[\"j\"]][[var_listcomp____b1394f1020f630cb5b96890e815444b7]]"                                     
#>  [9] "            for (k in var_listcomp____edc8004e1fc9172689566a16fc4a2cf6) {"                                                      
#> [10] "                if (!(i < 3)) {"                                                                                                
#> [11] "                  next"                                                                                                         
#> [12] "                }"                                                                                                              
#> [13] "                {"                                                                                                              
#> [14] "                  if (!(k < 3)) {"                                                                                              
#> [15] "                    next"                                                                                                       
#> [16] "                  }"                                                                                                            
#> [17] "                  var_listcomp____0cc901998ffca8eb9ab6e66438eabb65[[length(var_listcomp____0cc901998ffca8eb9ab6e66438eabb65) + "
#> [18] "                    1]] <- c(i, j, k)"                                                                                          
#> [19] "                }"                                                                                                              
#> [20] "            }"                                                                                                                  
#> [21] "        }"                                                                                                                      
#> [22] "    }"                                                                                                                          
#> [23] "    var_listcomp____0cc901998ffca8eb9ab6e66438eabb65"                                                                           
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
#> # A tibble: 4 × 6
#>   expression      min   median `itr/sec` mem_alloc `gc/sec`
#>   <bch:expr> <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
#> 1 a           16.66ms  17.79ms     56.8    172.1KB     39.2
#> 2 b            4.18ms   4.34ms    218.     172.1KB     33.7
#> 3 c          275.84ms 275.89ms      3.62    60.7KB     21.7
#> 4 d          838.37µs 878.59µs   1085.      60.7KB     28.0
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
#> # A tibble: 4 × 6
#>   expression   min median `itr/sec` mem_alloc `gc/sec`
#>   <bch:expr> <dbl>  <dbl>     <dbl> <bch:byt>    <dbl>
#> 1 a          2.05   2.14       467.    82.6KB     43.5
#> 2 b          0.416  0.438     2266.    26.2KB     36.3
#> 3 c          0.309  0.329     3013.    15.8KB     69.1
#> 4 d          0.165  0.177     5559.        0B     51.9
```

# Prior art

-   [lc](https://github.com/mailund/lc) Uses a similiar syntax as
    `complist`
-   [comprehenr](https://github.com/gdemin/comprehenr) Uses a similiar
    code generation approach as `complist` but with a different syntax.
