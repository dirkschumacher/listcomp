
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
#>  [2] "    var_listcomp____1dfca921 <- list()"                               
#>  [3] "    var_listcomp____300f3ed8 <- 1:10"                                 
#>  [4] "    for (x in var_listcomp____300f3ed8) for (y in x:5) {"             
#>  [5] "        if (!(x < 2)) {"                                              
#>  [6] "            next"                                                     
#>  [7] "        }"                                                            
#>  [8] "        var_listcomp____1dfca921[[length(var_listcomp____1dfca921) + "
#>  [9] "            1]] <- c(x, y)"                                           
#> [10] "    }"                                                                
#> [11] "    var_listcomp____1dfca921"                                         
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
#>  [2] "    var_listcomp____4feda89e <- list()"                                         
#>  [3] "    var_listcomp____41f11c1f <- 1:5"                                            
#>  [4] "    {"                                                                          
#>  [5] "        parallel_seq <- list(i = 1:10, j = 1:10)"                               
#>  [6] "        for (var_listcomp____4609e0d2 in seq_along(parallel_seq[[1]])) {"       
#>  [7] "            i <- parallel_seq[[\"i\"]][[var_listcomp____4609e0d2]]"             
#>  [8] "            j <- parallel_seq[[\"j\"]][[var_listcomp____4609e0d2]]"             
#>  [9] "            for (k in var_listcomp____41f11c1f) {"                              
#> [10] "                if (!(i < 3)) {"                                                
#> [11] "                  next"                                                         
#> [12] "                }"                                                              
#> [13] "                {"                                                              
#> [14] "                  if (!(k < 3)) {"                                              
#> [15] "                    next"                                                       
#> [16] "                  }"                                                            
#> [17] "                  var_listcomp____4feda89e[[length(var_listcomp____4feda89e) + "
#> [18] "                    1]] <- c(i, j, k)"                                          
#> [19] "                }"                                                              
#> [20] "            }"                                                                  
#> [21] "        }"                                                                      
#> [22] "    }"                                                                          
#> [23] "    var_listcomp____4feda89e"                                                   
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
#> 1 a            43.6ms  45.13ms     21.6    179.1KB     3.92
#> 2 b            13.7ms  16.82ms     56.6    179.1KB     9.75
#> 3 c             644ms 643.98ms      1.55    67.6KB    10.9 
#> 4 d             2.6ms   3.07ms    291.      67.6KB     9.98
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
#> 1 a          6.73   8.00       119.    89.5KB    14.6 
#> 2 b          1.36   1.83       399.    33.1KB     8.48
#> 3 c          0.788  0.924      784.    15.8KB    20.6 
#> 4 d          0.433  0.475     1840.        0B    19.7
```

# Prior art

  - [lc](https://github.com/mailund/lc) Uses a similiar syntax as
    `complist`
  - [comprehenr](https://github.com/gdemin/comprehenr) Uses a similiar
    code generation approach as `complist` but with a different syntax.
