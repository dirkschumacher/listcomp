
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
#>  [2] "    var_listcomp____db6da411c5c0b7fb68806eab70cbca15 <- list()"                                                       
#>  [3] "    var_listcomp____e914ec62bcf06fa4923666b0cb589de7 <- 1:10"                                                         
#>  [4] "    for (x in var_listcomp____e914ec62bcf06fa4923666b0cb589de7) for (y in x:5) {"                                     
#>  [5] "        if (!(x < 2)) {"                                                                                              
#>  [6] "            next"                                                                                                     
#>  [7] "        }"                                                                                                            
#>  [8] "        var_listcomp____db6da411c5c0b7fb68806eab70cbca15[[length(var_listcomp____db6da411c5c0b7fb68806eab70cbca15) + "
#>  [9] "            1]] <- c(x, y)"                                                                                           
#> [10] "    }"                                                                                                                
#> [11] "    var_listcomp____db6da411c5c0b7fb68806eab70cbca15"                                                                 
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
#>  [2] "    var_listcomp____9d4199269e91ca79bb0e0f7fd46ea9fb <- list()"                                                                 
#>  [3] "    var_listcomp____edc8004e1fc9172689566a16fc4a2cf6 <- 1:5"                                                                    
#>  [4] "    {"                                                                                                                          
#>  [5] "        parallel_seq <- list(i = 1:10, j = 1:10)"                                                                               
#>  [6] "        for (var_listcomp____ca49c60abe9df0ccd65068dce0f3206a in seq_along(parallel_seq[[1]])) {"                               
#>  [7] "            i <- parallel_seq[[\"i\"]][[var_listcomp____ca49c60abe9df0ccd65068dce0f3206a]]"                                     
#>  [8] "            j <- parallel_seq[[\"j\"]][[var_listcomp____ca49c60abe9df0ccd65068dce0f3206a]]"                                     
#>  [9] "            for (k in var_listcomp____edc8004e1fc9172689566a16fc4a2cf6) {"                                                      
#> [10] "                if (!(i < 3)) {"                                                                                                
#> [11] "                  next"                                                                                                         
#> [12] "                }"                                                                                                              
#> [13] "                {"                                                                                                              
#> [14] "                  if (!(k < 3)) {"                                                                                              
#> [15] "                    next"                                                                                                       
#> [16] "                  }"                                                                                                            
#> [17] "                  var_listcomp____9d4199269e91ca79bb0e0f7fd46ea9fb[[length(var_listcomp____9d4199269e91ca79bb0e0f7fd46ea9fb) + "
#> [18] "                    1]] <- c(i, j, k)"                                                                                          
#> [19] "                }"                                                                                                              
#> [20] "            }"                                                                                                                  
#> [21] "        }"                                                                                                                      
#> [22] "    }"                                                                                                                          
#> [23] "    var_listcomp____9d4199269e91ca79bb0e0f7fd46ea9fb"                                                                           
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
#> 1 a           16.45ms  17.56ms     57.8    172.1KB     39.9
#> 2 b            4.09ms   4.22ms    225.     172.1KB     35.8
#> 3 c          273.85ms    275ms      3.64    60.7KB     21.8
#> 4 d          827.46µs 862.85µs   1113.      60.7KB     28.0
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
#> 1 a          1.99   2.07       480.    82.6KB     43.4
#> 2 b          0.415  0.436     2280.    26.2KB     36.3
#> 3 c          0.307  0.328     3037.    15.8KB     69.1
#> 4 d          0.165  0.176     5601.        0B     54.1
```

# Prior art

-   [lc](https://github.com/mailund/lc) Uses a similiar syntax as
    `complist`
-   [comprehenr](https://github.com/gdemin/comprehenr) Uses a similiar
    code generation approach as `complist` but with a different syntax.
