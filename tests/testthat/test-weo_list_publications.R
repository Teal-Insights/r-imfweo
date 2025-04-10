test_that("weo_list_publications filters based on current date with mocked current year/month", {
  # Fake current date: Assume it's May 2024 (Spring release out, Fall not yet)
  fake_current_year <- 2024
  fake_current_month <- 5

  with_mocked_bindings(
    get_current_year = function() fake_current_year,
    get_current_month = function() fake_current_month,
    {
      result <- weo_list_publications(start_year = 2023, end_year = 2024)

      expect_s3_class(result, "data.frame")
      expect_true(all(result$year >= 2023 & result$year <= 2024))
      expect_true("Spring" %in% result$release)
      expect_true(!("Fall" %in% result$release[result$year == 2024])) # Fall not yet released
      expect_true("Fall" %in% result$release[result$year == 2023]) # Last year's Fall is fine
    }
  )
})

test_that("weo_list_publications respects check_latest = TRUE", {
  with_mocked_bindings(
    weo_get_latest_publication = function()
      list(year = 2024, release = "April"),
    {
      result <- weo_list_publications(
        start_year = 2023,
        end_year = 2024,
        check_latest = TRUE
      )

      expect_true("Spring" %in% result$release[result$year == 2024])
      expect_false("Fall" %in% result$release[result$year == 2024])
    }
  )
})
