# expr_text() --------------------------------------------------------

test_that("always returns single string", {
  out <- expr_text(quote({
    a + b
  }))
  expect_length(out, 1)
})

test_that("can truncate lines", {
  out <- expr_text(
    quote({
      a + b
    }),
    nlines = 2
  )
  expect_equal(out, "{\n...")
})


# expr_label() -------------------------------------------------------

test_that("quotes strings", {
  expect_equal(expr_label("a"), '"a"')
  expect_equal(expr_label("\n"), '"\\n"')
})

test_that("backquotes names", {
  expect_equal(expr_label(quote(x)), "`x`")
})

test_that("converts atomics to strings", {
  expect_equal(expr_label(0.5), "0.5")
})

test_that("expr_label() truncates blocks", {
  expect_identical(
    expr_label(quote({
      a + b
    })),
    "`{ ... }`"
  )
  expect_identical(
    expr_label(expr(function() {
      a
      b
    })),
    "`function() ...`"
  )
})

test_that("expr_label() truncates long calls", {
  long_call <- quote(foo())
  long_arg <- quote(longlonglonglonglonglonglonglonglonglonglonglong)
  long_call[c(2, 3, 4)] <- list(long_arg, long_arg, long_arg)
  expect_identical(expr_label(long_call), "`foo(...)`")
})

test_that("expr_label() NULL values come out as expected", {
  expect_identical(expr_label(NULL), "NULL")
})

# expr_name() --------------------------------------------------------

test_that("expr_name() with symbols, calls, and literals", {
  expect_identical(expr_name(quote(foo)), "foo")
  expect_identical(expr_name(quote(foo(bar))), "foo(bar)")
  expect_identical(expr_name(1L), "1")
  expect_identical(expr_name("foo"), "foo")
  expect_identical(expr_name(function() NULL), "function () ...")
  expect_identical(
    expr_name(expr(function() {
      a
      b
    })),
    "function() ..."
  )
  expect_identical(expr_name(NULL), "NULL")
  expect_error(expr_name(1:2), "must be")
  expect_error(expr_name(env()), "must be")
})

# --------------------------------------------------------------------

test_that("get_expr() supports closures", {
  expect_true(TRUE)
  return("Disabled because causes dplyr to fail")
  expect_identical(get_expr(identity), quote(x))
})

test_that("set_expr() supports closures", {
  fn <- function(x) x
  expect_equal(set_expr(fn, quote(y)), function(x) y)
})

test_that("expressions are deparsed and printed", {
  expect_output(expr_print(1:2), "<int: 1L, 2L>")
  expect_identical(expr_deparse(1:2), "<int: 1L, 2L>")
})

test_that("imaginary numbers with real part are not syntactic", {
  expect_true(is_syntactic_literal(0i))
  expect_true(is_syntactic_literal(na_cpl))
  expect_false(is_syntactic_literal(1 + 1i))
})

test_that("is_expression() detects non-parsable parse trees", {
  expect_true(is_expression(quote(foo(bar = baz(1, NULL)))))
  expect_false(is_expression(expr(foo(bar = baz(!!(1:2), NULL)))))
  expect_false(is_expression(call2(identity)))
})

test_that("is_expression() supports missing arguments", {
  expect_false(is_expression(missing_arg()))
  expect_false(is_expression(quote(foo(,))))
})

test_that("is_expression() supports quoted functions (#1499)", {
  expect_true(is_expression(parse_expr("function() NULL")))
})

test_that("is_expression() detects attributes (#1475)", {
  x <- structure(quote(foo()), attr = TRUE)
  expect_false(is_expression(x))
  expect_false(is_expression(expr(call(!!x))))
  expect_true(is_expression(quote({
    NULL
  })))
  expect_true(is_expression(quote(function() {
    NULL
  })))
})
