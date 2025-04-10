test_that(".onLoad initializes cache variables to NULL", {
  # Ensure that variables don't exist beforehand
  rm(list = ls(envir = .weo_cache), envir = .weo_cache)

  .onLoad(libname = NULL, pkgname = NULL)

  expect_null(.weo_cache$latest_publication)
  expect_null(.weo_cache$bulk)
  expect_null(.weo_cache$year)
  expect_null(.weo_cache$release)
})

test_that("weo_cache_reset sets all cache variables to NULL", {
  # Set cache values to something first
  .weo_cache$latest_publication <- "2025-04"
  .weo_cache$bulk <- data.frame(x = 1:3)
  .weo_cache$year <- 2025
  .weo_cache$release <- "April"

  weo_cache_reset()

  expect_null(.weo_cache$latest_publication)
  expect_null(.weo_cache$bulk)
  expect_null(.weo_cache$year)
  expect_null(.weo_cache$release)
})


test_that("get_current_year returns the current year", {
  expect_equal(get_current_year(), as.integer(format(Sys.Date(), "%Y")))
})

test_that("get_current_month returns the current month", {
  expect_equal(get_current_month(), as.integer(format(Sys.Date(), "%m")))
})
