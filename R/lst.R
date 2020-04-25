#' List comprehensions
#'
#' Syntactic sugar for for-loops
#'
#' @param element_expr an expression that will be collected
#' @param ... either logical expressions or a named parameters with an iterable
#'   sequence.
#' @param .compile compile the resulting for loop to bytecode befor eval
#'
#' @examples
#' gen_list(c(x, y), x = 1:10, y = 1:10, x + y == 10, x < y)
#' z <- 10
#' gen_list(c(x, y), x = 1:10, y = 1:10, x + y == !!z, x < y)
#' @import rlang
#' @export
gen_list <- function(element_expr, ..., .compile = TRUE) {
  code <- translate(enquo(element_expr), enquos(...))
  code <- if (.compile) {
    compiler::compile(code)
  } else {
    code
  }
  eval_bare(code, env = new_environment(parent = caller_env()))
}

translate <- function(element_expr, quosures) {
  quo_names <- names(quosures)
  is_index <- quo_names != ""
  start_val <- get_expr(
    quo({
      res$set(as.character(i_____), !!get_expr(element_expr))
      i_____ <- i_____ + 1
    })
  )
  has_symbols <- vapply(quosures, function(x) {
    length(all.vars(get_expr(x))) > 0
  }, logical(1L))
  loop <- Reduce(
    f = function(acc, i) {
      quosure <- get_expr(quosures[[i]])
      name <- names(quosures)[[i]]
      make_for <- name != ""
      if (make_for) {
        iter_name <- if (has_symbols[[i]]) {
          quosure
        } else {
          iter_symbol_name(name)
        }
        get_expr(quo(
          `for`(!!as.symbol(name), !!iter_name, {
            !!acc
          })
        ))
      } else {
        get_expr(quo({
          if (!((!!quosure))) {
            !!next_call # for R CMD check
          }
          !!acc
        }))
      }
    },
    x = rev(seq_along(quosures)),
    init = start_val
  )
  loop <- get_expr(loop)
  top_level_assignments <- mapply(
    function(val, name) {
      s <- iter_symbol_name(name)
      get_expr(quo(`<-`(!!s, !!get_expr(val))))
    }, quosures[!has_symbols & is_index],
    quo_names[!has_symbols & is_index]
  )
  get_expr(
    quo({
      res <- fastmap::fastmap()
      i_____ <- 1
      !!!top_level_assignments
      !!loop
      res <- res$as_list(sort = FALSE)
      res <- res[order(as.numeric(names(res)))] # need to sort by numeric
      names(res) <- NULL
      res
    })
  )
}

next_call <- parse(text = "next")[[1]]

iter_symbol_name <- function(name) {
  as.symbol(paste0("iter_____", name))
}
