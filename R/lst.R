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
#' lst(c(x, y), x = 1:10, y = 1:10, x + y == 10, x < y)
#' z <- 10
#' lst(c(x, y), x = 1:10, y = 1:10, x + y == !!z, x < y)
#'
#' @export
lst <- function(element_expr, ..., .compile = TRUE) {
  quosures <- rlang::enquos(...)
  code <- translate(rlang::enquo(element_expr), quosures)
  rlang::eval_bare(
    if (.compile) {
      compiler::compile(code)
    } else {
      code
    }
  )
}

translate <- function(element_expr, quosures) {
  quo_names <- names(quosures)
  is_index <- quo_names != ""
  start_val <- rlang::get_expr(
    rlang::quo({
      `<-`(
        res[[as.character(i_____)]],
        !!rlang::get_expr(element_expr)
      )
      i_____ <- i_____ + 1
    })
  )
  has_symbols <- vapply(quosures, function(x) {
    length(all.vars(rlang::get_expr(x))) > 0
  }, logical(1L))
  loop <- Reduce(
    f = function(acc, i) {
      quosure <- rlang::get_expr(quosures[[i]])
      name <- names(quosures)[[i]]
      make_for <- name != ""
      if (make_for) {
        iter_name <- if (has_symbols[[i]]) {
          quosure
        } else {
          iter_symbol_name(name)
        }
        rlang::get_expr(rlang::quo(
          `for`(!!as.symbol(name), !!iter_name, {
            !!acc
          })
        ))
      } else {
        rlang::get_expr(rlang::quo({
          if (!((!!quosure))) {
            !!(parse(text = "next()")[[1]]) # for R CMD check
          }
          !!acc
        }))
      }
    },
    x = rev(seq_along(quosures)),
    init = start_val
  )
  loop <- rlang::get_expr(loop)
  top_level_assignments <- mapply(
    function(val, name) {
      s <- iter_symbol_name(name)
      rlang::get_expr(rlang::quo(`<-`(!!s, !!rlang::get_expr(val))))
    }, quosures[!has_symbols & is_index],
    quo_names[!has_symbols & is_index]
  )
  # uses environments for list contruction
  # https://stackoverflow.com/a/29482211/2798441
  rlang::get_expr(
    rlang::quo({
      res <- new.env()
      i_____ <- 1
      !!!top_level_assignments
      !!loop
      res <- as.list(res, sorted = FALSE)
      res <- res[order(as.numeric(names(res)))]
      names(res) <- NULL
      res
    })
  )
}

iter_symbol_name <- function(name) {
  as.symbol(paste0("iter_____", name))
}
