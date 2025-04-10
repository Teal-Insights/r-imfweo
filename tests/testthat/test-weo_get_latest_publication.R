test_that("weo_get_latest_publication returns cached result if available", {
  .weo_cache$latest_publication <- list(year = 2024, release = "Spring")

  result <- weo_get_latest_publication()
  expect_equal(result, list(year = 2024, release = "Spring"))

  # Clean up
  .weo_cache$latest_publication <- NULL
})

test_that("weo_get_latest_publication caches first valid publication", {
  # Reset cache
  .weo_cache$latest_publication <- NULL

  # Create a fake response object
  fake_response <- structure(
    list(
      url = "https://www.imf.org/en/Publications/WEO/weo-database/2024/October"
    ),
    class = "httr2_response"
  )

  with_mocked_bindings(
    get_current_year = function() 2024,
    request = function(url) structure(list(url = url), class = "httr2_request"),
    req_options = function(req, ...) req,
    req_user_agent = function(req, ...) req,
    req_perform = function(req) fake_response,
    {
      result <- weo_get_latest_publication()

      expect_equal(result, list(year = 2024, release = "Fall"))
      expect_equal(
        .weo_cache$latest_publication,
        list(year = 2024, release = "Fall")
      )
    }
  )
})

test_that("cli_alert_info is shown when quiet = FALSE", {
  .weo_cache$latest_publication <- NULL

  with_mocked_bindings(
    get_current_year = function() 2024,
    request = function(url) structure(list(url = url), class = "httr2_request"),
    req_options = function(req, ...) req,
    req_user_agent = function(req, ...) req,
    req_perform = function(req) NULL,
    {
      expect_message(
        tryCatch(
          weo_get_latest_publication(quiet = FALSE),
          error = function(e) NULL
        ),
        "Fetching and cacheing latest publication..."
      )
    }
  )
})

test_that("cli_abort is triggered if no valid publication is found", {
  .weo_cache$latest_publication <- NULL

  with_mocked_bindings(
    get_current_year = function() 2024,
    request = function(url) structure(list(url = url), class = "httr2_request"),
    req_options = function(req, ...) req,
    req_user_agent = function(req, ...) req,
    req_perform = function(req) NULL, # Simulate all fetches fail
    {
      expect_error(
        weo_get_latest_publication(quiet = TRUE),
        "No valid WEO publication found"
      )
    }
  )
})
