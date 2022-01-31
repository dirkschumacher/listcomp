#' List comprehensions
#'
#' Create lists of elements using an expressive syntax. Internally nested
#' for-loops are created and compiled that generate the list.
#'
#' @param element_expr an expression that will be collected
#' @param ... either a logical expression that returns a length 1 result.
#'   A named list of equal length sequences that are iterated over
#'   in parallel or a named parameter with an iterable sequence.
#' @param .compile compile the resulting for loop to bytecode befor eval
#' @param .env the parent environment in which all the elements are being
#'   evaluated.
#'
#' @details
#'
#' For parallel iterations all elements in the \code{list} need to be of
#' equal length. This is not checked at runtime at the moment.
#'
#' @return
#' A list of all generated values. The element-type is determined by the
#' parameter \code{element_expr}.
#'
#' @examples
#' gen_list(c(x, y), x = 1:10, y = 1:10, x + y == 10, x < y)
#' z <- 10
#' gen_list(c(x, y), x = 1:10, y = 1:10, x + y == !!z, x < y)
#'
#' # it is also possible to iterate in parallel by passing a list of
#' # sequences
#' gen_list(c(x, y), list(x = 1:10, y = 1:10), (x + y) %in% c(4, 6))
#'
#' @import rlang
#' @importFrom compiler compile
#' @export
gen_list <- function(element_expr, ...,
                     .compile = TRUE, .env = parent.frame()) {
  code <- translate(enquo(element_expr), enquos(...))
  code <- if (.compile) {
    compile(code, env = .env)
  } else {
    code
  }
  eval_bare(code, env = new_environment(parent = .env))
}

translate <- function(element_expr, quosures) {
  quosures <- classify_quosures(quosures)
  start_val <- get_expr(quo(
    .lc_result[[length(.lc_result) + 1]] <- !!get_expr(element_expr)
  ))
  loop_code <- Reduce(
    f = function(acc, el) {
      generate_code(acc, el)
    },
    x = rev(quosures),
    init = start_val
  )
  top_level_assignments <- generate_top_level_assignments(quosures)
  loop_code <- get_expr(loop_code)
  get_expr(
    quo({
      .lc_result <- list()
      !!!top_level_assignments
      !!loop_code
      .lc_result
    })
  )
}

generate_top_level_assignments <- function(quosures) {
  mapply(
    function(val) {
      s <- iter_symbol_name(val$name)
      get_expr(quo((!!assignment_symbol)(!!s, !!get_expr(val$quosure))))
    },
    Filter(function(x) !x$has_symbols && x$is_index, quosures),
    SIMPLIFY = FALSE,
    USE.NAMES = FALSE
  )
}

classify_quosures <- function(quosures) {
  mapply(
    classify_quosure, quosures, names(quosures),
    SIMPLIFY = FALSE,
    USE.NAMES = FALSE
  )
}

classify_quosure <- function(x, name) {
  type <- "named_sequence"
  if (name == "") {
    expr <- get_expr(x)
    if (length(expr) >= 1 && expr[[1]] == "list") {
      type <- "parallel_sequence"
    } else {
      type <- "condition"
    }
  }
  structure(
    list(
      quosure = x,
      name = name,
      has_symbols = length(all.vars(get_expr(x))) > 0,
      is_index = name != ""
    ),
    class = type
  )
}

generate_code <- function(acc, el) UseMethod("generate_code", el)

generate_code.named_sequence <- function(acc, el) {
  iter_name <- if (el$has_symbols) {
    get_expr(el$quosure)
  } else {
    iter_symbol_name(el$name)
  }
  get_expr(quo(
    (!!for_symbol)(!!as.symbol(el$name), !!iter_name, !!acc)
  ))
}

generate_code.condition <- function(acc, el) {
  get_expr(quo({
    if (!((!!get_expr(el$quosure)))) {
      !!next_call
    }
    !!acc
  }))
}

generate_code.parallel_sequence <- function(acc, el) {
  names <- names(get_expr(el$quosure))[-1]
  stopifnot(all(names != ""))
  iter_name <- as.symbol(".lc_ps_it")
  local_variables <- lapply(names, function(name) {
    var <- as.symbol(name)
    get_expr(
      quo(
        (!!assignment_symbol)(
          !!var,
          parallel_seq[[!!name]][[!!iter_name]]
        )
      )
    )
  })
  get_expr(quo({
    parallel_seq <- !!get_expr(el$quosure)
    (!!for_symbol)(!!iter_name, seq_along(parallel_seq[[1]]), {
      !!!local_variables
      !!acc
    })
  }))
}

iter_symbol_name <- function(name) {
  as.symbol(paste0(".lci_", name))
}

# for codetools to prevent R CMD check warnings
next_call <- parse(text = "next")[[1]]
for_symbol <- as.symbol("for")
assignment_symbol <- as.symbol("<-")
