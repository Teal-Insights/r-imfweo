test_that("weo_list_publications handles basic cases correctly", {
  # Mock date and time functions
  with_mocked_bindings(
    get_current_year = function() 2023,
    get_current_month = function() 9,
    {
      # Test with default parameters
      result <- weo_list_publications()

      # Check structure
      expect_s3_class(result, "tbl_df")
      expect_named(result, c("year", "release", "month"))

      # Check content
      expect_true(all(result$year >= 2007))
      expect_true(all(result$year <= 2023))
      expect_true(all(result$release %in% c("Spring", "Fall")))
      expect_true(all(result$month %in% c("April", "October")))

      # Check filtering logic for current year
      # Since current date is 2023-09-15, we should have April 2023 but not
      # October 2023
      expect_true(any(result$year == 2023 & result$month == "April"))
      expect_false(any(result$year == 2023 & result$month == "October"))

      # Check sorting
      expect_equal(result$year, sort(result$year))

      # For same year, April should come before October
      same_year <- result |> dplyr::filter(year == 2022)
      expect_equal(same_year$month, c("April", "October"))
    }
  )
})

test_that("weo_list_publications respects start_year and end_year parameters", {
  with_mocked_bindings(
    get_current_year = function() 2023,
    get_current_month = function() 9,
    {
      # Test with custom year range
      result <- weo_list_publications(start_year = 2020, end_year = 2022)

      # Check bounds
      expect_equal(min(result$year), 2020)
      expect_equal(max(result$year), 2022)

      # Check all expected publications are present
      expected_count <- 3 * 2 # 3 years, 2 publications per year
      expect_equal(nrow(result), expected_count)

      # Test invalid year range
      expect_error(
        weo_list_publications(start_year = 2025, end_year = 2020),
        "`start_year` must be smaller than `end_year`",
        fixed = TRUE
      )

      # Test non-numeric years
      expect_error(
        weo_list_publications(start_year = "2020", end_year = 2022),
        "`start_year` and `end_year` must be numeric",
        fixed = TRUE
      )

      expect_error(
        weo_list_publications(start_year = 2020, end_year = "2022"),
        "`start_year` and `end_year` must be numeric",
        fixed = TRUE
      )
    }
  )
})

test_that("weo_list_publications handles check_latest parameter correctly", {
  with_mocked_bindings(
    get_current_year = function() 2023,
    get_current_month = function() 9,
    weo_get_latest_publication = function() {
      list(year = 2023, release = "April")
    },
    {
      # Test with check_latest = TRUE
      result_with_check <- weo_list_publications(check_latest = TRUE)

      # Check filtering based on latest publication
      expect_true(any(
        result_with_check$year == 2023 &
          result_with_check$month == "April"
      ))
      expect_false(any(
        result_with_check$year == 2023 &
          result_with_check$month == "October"
      ))

      # Different mock for latest publication
      with_mocked_bindings(
        weo_get_latest_publication = function() {
          list(year = 2022, release = "October")
        },
        {
          # This should only include publications up to October 2022
          result_with_older <- weo_list_publications(
            check_latest = TRUE
          )
          expect_equal(max(result_with_older$year), 2022)
          expect_true(any(
            result_with_older$year == 2022 &
              result_with_older$month == "October"
          ))
          expect_false(any(result_with_older$year == 2023))
        }
      )
    }
  )
})

test_that("weo_list_publications handles edge cases", {
  # Test with current month = April
  with_mocked_bindings(
    get_current_year = function() 2023,
    get_current_month = function() 4,
    {
      # April release should be included but not October
      result <- weo_list_publications(start_year = 2023, end_year = 2023)
      expect_equal(nrow(result), 1)
      expect_equal(result$month, "April")
    }
  )

  # Test with current month = October
  with_mocked_bindings(
    get_current_year = function() 2023,
    get_current_month = function() 10,
    {
      # Both April and October releases should be included
      result <- weo_list_publications(start_year = 2023, end_year = 2023)
      expect_equal(nrow(result), 2)
      expect_equal(result$month, c("April", "October"))
    }
  )

  # Test with current month = January (no publications for current year yet)
  with_mocked_bindings(
    get_current_year = function() 2023,
    get_current_month = function() 1,
    {
      # No publications for current year
      result <- weo_list_publications(start_year = 2023, end_year = 2023)
      expect_equal(nrow(result), 0)

      # Should include previous years
      result_with_prev <- weo_list_publications(
        start_year = 2022,
        end_year = 2023
      )
      expect_equal(max(result_with_prev$year), 2022)
    }
  )
})

test_that("get_current_year works", {
  expect_no_error(get_current_year())
})

test_that("get_current_month works", {
  expect_no_error(get_current_month())
})
