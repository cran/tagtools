A <- matrix(c(1, -0.5, 0.1, 0.8, -0.2, 0.6, 0.5, -0.9, -0.7),
            byrow = TRUE, nrow = 3, ncol = 3
)
M <- matrix(c(1.3, -0.25, 0.16, 0.78, -0.3, 0.5, 0.5, -0.49, -0.6),
            byrow = TRUE, nrow = 3, ncol = 3
)

sample <- c(-1.2968892, -1.4349892, -1.3165832)
test_that("function works", {
  expect_equal(round(inclination(A, M), digits=7), sample)
})

set <- matrix(c(20,30,15))
test_that("function does not works", {
  expect_error(inclination(set,M), "A must be an acceleration matrix")
})