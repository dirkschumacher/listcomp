#' List comprehensions
#'
#' Create lists of elements using an expressive syntax. Internally nested
#' for-loops are created and compiled that generate the list.
#'
#' @param element_expr an expression that will be collected
#' @param ... either logical expressions or named parameters with an iterable
#'   sequence.
#' @param .compile compile the resulting for loop to bytecode befor eval
#'
#' @return
#' A list of all generated values. The element-type is determined by the
#' parameter \code{element_expr}.
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
    compiler::compile(code, env = caller_env())
  } else {
    code
  }
  eval_bare(code, env = new_environment(parent = caller_env()))
}

translate <- function(element_expr, quosures) {
  quo_names <- names(quosures)
  is_index <- quo_names != ""
  start_val <- get_expr(
    quo(res_____[[length(res_____) + 1]] <- !!get_expr(element_expr))
  )
  has_symbols <- vapply(quosures, function(x) {
    length(all.vars(get_expr(x))) > 0
  }, logical(1L))
  for_symbol <- as.symbol("for") # to prevent a codetools bug
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
          (!!for_symbol)(!!as.symbol(name), !!iter_name, !!acc)
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
  assignment_symbol <- as.symbol("<-") # for codetools
  top_level_assignments <- mapply(
    function(val, name) {
      s <- iter_symbol_name(name)
      get_expr(quo((!!assignment_symbol)(!!s, !!get_expr(val))))
    },
    quosures[!has_symbols & is_index],
    quo_names[!has_symbols & is_index]
  )
  loop <- get_expr(loop)
  get_expr(
    quo({
      res_____ <- list()
      !!!top_level_assignments
      !!loop
      res_____
    })
  )
}

next_call <- parse(text = "next")[[1]]

iter_symbol_name <- function(name) {
  as.symbol(paste0("iter_____", name))
}
