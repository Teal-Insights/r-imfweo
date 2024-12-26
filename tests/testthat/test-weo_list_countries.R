test_that("weo_list_countries returns correct country information", {
  countries <- weo_list_countries()

  # Test structure
  expect_s3_class(countries, "tbl_df")
  expect_named(countries, c("country_code", "country_name"))

  # Test content
  expect_true(nrow(countries) > 100) # Should have many countries
  expect_true(all(!is.na(countries$country_code)))
  expect_true(all(!is.na(countries$country_name)))

  # Test specific countries exist
  major_economies <- c("USA", "GBR", "DEU", "FRA", "JPN", "CHN")
  expect_true(all(major_economies %in% countries$country_code))

  # Test pattern matching
  united_countries <- weo_list_countries("united")
  expect_true(all(grepl("united", tolower(united_countries$country_name))))
})
