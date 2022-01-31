
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
#>  [2] "    .lc_result <- list()"                               
#>  [3] "    .lci_x <- 1:10"                                     
#>  [4] "    for (x in .lci_x) for (y in x:5) {"                 
#>  [5] "        if (!(x < 2)) {"                                
#>  [6] "            next"                                       
#>  [7] "        }"                                              
#>  [8] "        .lc_result[[length(.lc_result) + 1]] <- c(x, y)"
#>  [9] "    }"                                                  
#> [10] "    .lc_result"                                         
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
#>  [2] "    .lc_result <- list()"                                       
#>  [3] "    .lci_k <- 1:5"                                              
#>  [4] "    {"                                                          
#>  [5] "        parallel_seq <- list(i = 1:10, j = 1:10)"               
#>  [6] "        for (.lc_ps_it in seq_along(parallel_seq[[1]])) {"      
#>  [7] "            i <- parallel_seq[[\"i\"]][[.lc_ps_it]]"            
#>  [8] "            j <- parallel_seq[[\"j\"]][[.lc_ps_it]]"            
#>  [9] "            for (k in .lci_k) {"                                
#> [10] "                if (!(i < 3)) {"                                
#> [11] "                  next"                                         
#> [12] "                }"                                              
#> [13] "                {"                                              
#> [14] "                  if (!(k < 3)) {"                              
#> [15] "                    next"                                       
#> [16] "                  }"                                            
#> [17] "                  .lc_result[[length(.lc_result) + 1]] <- c(i, "
#> [18] "                    j, k)"                                      
#> [19] "                }"                                              
#> [20] "            }"                                                  
#> [21] "        }"                                                      
#> [22] "    }"                                                          
#> [23] "    .lc_result"                                                 
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
#> 1 a           16.09ms  17.19ms     58.8      112KB     39.2
#> 2 b            4.04ms   4.13ms    227.       112KB     35.9
#> 3 c          273.06ms 273.08ms      3.66      280B     22.0
#> 4 d          785.56µs 813.97µs   1182.        280B     28.0
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
#> 1 a          1.95   2.00       494.    56.7KB     45.8
#> 2 b          0.390  0.404     2452.      280B     38.5
#> 3 c          0.308  0.326     3037.    15.8KB     69.2
#> 4 d          0.163  0.174     5705.        0B     56.4
```

# Related packages

-   [lc](https://github.com/mailund/lc) Uses a similar syntax as
    `listcomp`
-   [comprehenr](https://github.com/gdemin/comprehenr) Uses a similar
    code generation approach as `listcomp` but with a different syntax.
-   [listcompr](https://github.com/patrickroocks/listcompr) Uses a
    similar syntax as `listcomp` and offers special generator functions
    for lists, vectors, data.frames and matrices.
